//
//  BookSearchService.swift
//  BookCompanion
//
//  Created by Shree on 06/02/2026.
//

import Foundation

// MARK: - Models

struct BookSearchResult: Identifiable, Equatable {
    let id: String
    let title: String
    let authors: [String]
    let pageCount: Int?
    let language: String?
    let thumbnailURL: String?
    let categories: [String]?
    
    var author: String {
        authors.joined(separator: ", ")
    }
    
    var estimatedChapters: Int {
        guard let pages = pageCount else { return 20 }
        return max(1, pages / 15)
    }
    
    var detectedLanguage: Language {
        guard let lang = language?.lowercased() else { return .english }
        
        if lang.contains("hi") || lang == "hindi" {
            return .hindi
        } else if lang.contains("mr") || lang == "marathi" {
            return .marathi
        } else {
            return .english
        }
    }
    
    var isFiction: Bool {
        guard let cats = categories else { return true }
        let fictionCategories = ["fiction", "novel", "literature", "fantasy", "mystery", "romance", "thriller"]
        return cats.contains { cat in
            fictionCategories.contains { cat.lowercased().contains($0) }
        }
    }
    
    static func == (lhs: BookSearchResult, rhs: BookSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Service

final class BookSearchService {
    
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }
    
    func search(query: String) async throws -> [BookSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        // Detect script
        let isNonLatin = query.unicodeScalars.contains { scalar in
            (0x0900...0x097F).contains(scalar.value)
        }
        
        // Build search query
        let searchQuery: String
        if isNonLatin {
            searchQuery = query
        } else {
            searchQuery = "\(query)+subject:fiction"
        }
        
        // Call YOUR backend instead of Google directly
        var components = URLComponents(string: "\(Config.apiEndpoint)/api/search-books")!
        
        var queryItems = [
            URLQueryItem(name: "query", value: searchQuery),
            URLQueryItem(name: "maxResults", value: "40")
        ]
        
        if !isNonLatin {
            queryItems.append(URLQueryItem(name: "langRestrict", value: "en"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw BookSearchError.invalidURL
        }
        
        print("🔍 Searching: \(query)")
        
        var request = URLRequest(url: url)
        request.addValue(Config.appSecret, forHTTPHeaderField: "X-App-Secret")
   
        
        // Retry logic
        var lastError: Error?
        for attempt in 1...2 {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw BookSearchError.requestFailed
                }
                
                print("📡 Response status: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    if attempt < 2 {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        continue
                    }
                    throw BookSearchError.requestFailed
                }
                
                // Parse Google Books response
                let decoder = JSONDecoder()
                let googleResponse = try decoder.decode(GoogleBooksResponse.self, from: data)
                
                guard let items = googleResponse.items, !items.isEmpty else {
                    throw BookSearchError.noResults
                }
                
                print("✅ Found \(items.count) results")
                
                // Convert to our model
                let results = items.compactMap { item -> BookSearchResult? in
                    guard !item.volumeInfo.title.isEmpty,
                          let authors = item.volumeInfo.authors,
                          !authors.isEmpty else {
                        return nil
                    }
                    
                    let thumbnail = item.volumeInfo.imageLinks?.thumbnail?
                        .replacingOccurrences(of: "http://", with: "https://")
                    
                    return BookSearchResult(
                        id: item.id,
                        title: item.volumeInfo.title,
                        authors: authors,
                        pageCount: item.volumeInfo.pageCount,
                        language: item.volumeInfo.language,
                        thumbnailURL: thumbnail,
                        categories: item.volumeInfo.categories
                    )
                }
                
                if isNonLatin {
                    return Array(results.prefix(20))
                }
                
                return filterAndSortResults(results, query: query)
                
            } catch {
                lastError = error
                if attempt < 2 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }
        
        throw lastError ?? BookSearchError.requestFailed
    }
       
    private func filterAndSortResults(_ results: [BookSearchResult], query: String) -> [BookSearchResult] {
        let lowercaseQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let scored = results.map { result -> (result: BookSearchResult, score: Int) in
            var score = 0
            let title = result.title.lowercased()
            let author = result.author.lowercased()
            
            
            // EXACT MATCHES (Highest Priority)
            if title == lowercaseQuery {
                score += 500  // Exact title match
            } else if title == "the \(lowercaseQuery)" || title == "\(lowercaseQuery), the" {
                score += 450  // Title with "the"
            }
            
            // TITLE STARTS WITH
            if title.hasPrefix(lowercaseQuery + " ") || title.hasPrefix(lowercaseQuery + ":") {
                score += 300
            } else if title.hasPrefix("the \(lowercaseQuery) ") {
                score += 280
            }
            
            // TITLE CONTAINS (as whole word)
            let titleWords = title.components(separatedBy: .whitespaces)
            if titleWords.contains(lowercaseQuery) {
                score += 200
            } else if title.contains(lowercaseQuery) {
                score += 100
            }
            
            // AUTHOR MATCHES
            if author.contains(lowercaseQuery) {
                score += 150
            }
            
            // QUALITY SIGNALS
            if let pages = result.pageCount {
                // Novel length (150-600 pages): +100
                if pages >= 150 && pages <= 600 {
                    score += 100
                } else if pages >= 100 && pages < 150 {
                    score += 50
                } else if pages > 600 && pages < 1000 {
                    score += 30
                }
                
                // Penalty for textbooks/reference (very long)
                if pages > 1000 {
                    score -= 100
                }
                
                // Penalty for very short
                if pages < 100 {
                    score -= 50
                }
            } else {
                score -= 20  // No page count is suspicious
            }
            
            // Fiction bonus
            if result.isFiction {
                score += 50
            }
            
            // Has thumbnail
            if result.thumbnailURL != nil {
                score += 30
            }
            
            // Penalty for titles with subtitles about other things
            if title.contains("concordance") || title.contains("commentary") ||
               title.contains("analysis") || title.contains("study guide") ||
               title.contains("places") || title.contains("philosophy") ||
               title.contains("encyclopedia") || title.contains("companion") ||
               title.contains("guide to") || title.contains("handbook") {
                score -= 200
            }
            
            return (result, score)
        }
        
        let sorted = scored
            .sorted { $0.score > $1.score }
            .filter { $0.score > 0 }
            .prefix(20)
        
        // Debug output
        print("\n📊 Top Results:")
        for (index, item) in sorted.enumerated() {
            let pages = item.result.pageCount ?? 0
            let fiction = item.result.isFiction ? "📚" : "📖"
            print("  \(index + 1). [\(item.score)] \(fiction) \(item.result.title) (\(pages)p)")
        }
        print("")
        
        return Array(sorted.map { $0.result })
    }
}

// MARK: - Google Books Response Models

private struct GoogleBooksResponse: Codable {
    let items: [BookItem]?
}

private struct BookItem: Codable {
    let id: String
    let volumeInfo: VolumeInfo
}

private struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let pageCount: Int?
    let language: String?
    let imageLinks: ImageLinks?
    let categories: [String]?
}

private struct ImageLinks: Codable {
    let thumbnail: String?
    let smallThumbnail: String?
}

// MARK: - Errors

enum BookSearchError: LocalizedError {
    case invalidURL
    case requestFailed
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid search request"
        case .requestFailed:
            return "Failed to search for books. Please check your internet connection."
        case .noResults:
            return "No books found. Try a different search term."
        }
    }
} 
