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
    
    static func == (lhs: BookSearchResult, rhs: BookSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Service

final class BookSearchService {
    
    private let baseURL = "https://bookcompanion-api.vercel.app/api/search-books"
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
        
        // Build URL components
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "maxResults", value: "40")
        ]
        
        guard let url = components.url else {
            throw BookSearchError.invalidURL
        }
        
        print("🔍 Searching: \(query)")
        
        var request = URLRequest(url: url)
        request.setValue(Config.appSecret, forHTTPHeaderField: "X-App-Secret")
        let (data, response) = try await session.data(for: request)
        // Debug: Print raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Raw API Response (first 500 chars): \(String(jsonString.prefix(500)))")
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BookSearchError.requestFailed
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw BookSearchError.requestFailed
        }
        
        // Parse backend response
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(BooksAPIResponse.self, from: data)
        
        guard !apiResponse.books.isEmpty else {
            throw BookSearchError.noResults
        }
        
        print("✅ Found \(apiResponse.books.count) results")
        
        // Convert to BookSearchResult
        let results = apiResponse.books.map { book in
            BookSearchResult(
                id: book.id,
                title: book.title,
                authors: book.authors,
                pageCount: book.pageCount,
                language: book.language,
                thumbnailURL: book.coverImage ?? book.googleThumbnail,
                categories: book.categories.isEmpty ? nil : book.categories
            )
        }
        
        return Array(results.prefix(20))
    }
}

// MARK: - Backend Response Models

private struct BooksAPIResponse: Codable {
    let totalItems: Int
    let books: [BackendBook]
}

private struct BackendBook: Codable {
    let id: String
    let title: String
    let authors: [String]
    let pageCount: Int?
    let language: String?
    let categories: [String]
    let coverImage: String?
    let googleThumbnail: String?
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
