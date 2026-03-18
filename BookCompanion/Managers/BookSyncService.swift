//
//  BookSyncService.swift
//  BookCompanion
//
//  Created by Shree on 23/02/2026.
//

import Foundation
import Combine

@MainActor
class BookSyncService: ObservableObject {
    
    static let shared = BookSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private init() {}
    
    // ============================================
    // SYNC ALL BOOKS TO CLOUD
    // ============================================
    
    func syncBooksToCloud(_ books: [Book]) async throws {
        guard let token = KeychainManager.shared.getUserToken() else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Transform books to sync format
        // Transform books to sync format
        let booksData = books.map { book -> [String: Any] in
            var bookDict: [String: Any] = [
                "id": book.id.uuidString,
                "title": book.title,
                "author": book.author,
                "language": book.language.rawValue,
                "totalChapters": book.totalChapters,
                "currentChapter": book.readingProgress?.chapter ?? 1,
                "createdAt": ISO8601DateFormatter().string(from: book.createdAt)
            ]
            
            // Add optional fields only if present
            if let coverURL = book.coverImageURL {
                bookDict["coverImageURL"] = coverURL
            }
            
            if let pages = book.pageCount {
                bookDict["pageCount"] = pages
            }

            // Book type — drives prompt branching on backend
            bookDict["bookType"] = book.bookType.rawValue

            return bookDict
        }
        
        let requestBody: [String: Any] = [
            "books": booksData
        ]
        
        let url = URL(string: "\(Config.apiEndpoint)/api/books/sync")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SyncError.syncFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if json?["success"] as? Bool == true {
            lastSyncDate = Date()
            print("✅ Synced \(books.count) books to cloud")
        } else {
            throw SyncError.syncFailed
        }
    }
    
    // ============================================
    // FETCH BOOKS FROM CLOUD
    // ============================================
    
    func fetchBooksFromCloud() async throws -> [Book] {
        guard let token = KeychainManager.shared.getUserToken() else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let url = URL(string: "\(Config.apiEndpoint)/api/books/sync")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SyncError.fetchFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let success = json?["success"] as? Bool,
              success,
              let booksData = json?["books"] as? [[String: Any]] else {
            throw SyncError.invalidResponse
        }
        
        // Parse books
        let books = booksData.compactMap { bookDict -> Book? in
            guard let idString = bookDict["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let title = bookDict["title"] as? String,
                  let author = bookDict["author"] as? String else {
                return nil
            }
            
            let languageString = bookDict["language"] as? String ?? "en"
            let language = Language(rawValue: languageString) ?? .english
            
            let totalChapters = bookDict["total_chapters"] as? Int ?? 0
            let currentChapter = bookDict["current_chapter"] as? Int ?? 1
            let coverImageURL = bookDict["cover_image_url"] as? String
            let pageCount = bookDict["page_count"] as? Int
            let bookTypeRaw = bookDict["book_type"] as? String ?? "fiction"
            let bookType = BookType(rawValue: bookTypeRaw) ?? .fiction
            
            // Parse created_at
            var createdAt = Date()
            if let createdAtString = bookDict["created_at"] as? String {
                let formatter = ISO8601DateFormatter()
                createdAt = formatter.date(from: createdAtString) ?? Date()
            }
            
            return Book(
                id: id,
                title: title,
                author: author,
                language: language,
                totalChapters: totalChapters,
                pageCount: pageCount,
                coverImageURL: coverImageURL,
                createdAt: createdAt,
                bookType: bookType,
                readingProgress: ReadingProgress(
                    id: UUID(),
                    bookId: id,
                    chapter: currentChapter,
                    language: language,
                    updatedAt: Date()
                )
            )
        }
        
        lastSyncDate = Date()
        print("✅ Fetched \(books.count) books from cloud")
        
        return books
    }
    
    // ============================================
    // UPDATE SINGLE BOOK
    // ============================================
    
    func updateBook(_ book: Book) async throws {
        guard let token = KeychainManager.shared.getUserToken() else {
            throw SyncError.notAuthenticated
        }
        
        let requestBody: [String: Any] = [
            "bookId": book.id.uuidString,
            "updates": [
                "currentChapter": book.readingProgress?.chapter ?? 1,
                "language": book.language.rawValue
            ]
        ]
        
        let url = URL(string: "\(Config.apiEndpoint)/api/books/sync")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SyncError.updateFailed
        }
        
        print("✅ Updated book: \(book.title)")
    }
    
    // ============================================
    // DELETE BOOK
    // ============================================
    
    func deleteBook(_ bookId: UUID) async throws {
        guard let token = KeychainManager.shared.getUserToken() else {
            throw SyncError.notAuthenticated
        }
        
        let requestBody: [String: Any] = [
            "bookId": bookId.uuidString
        ]
        
        let url = URL(string: "\(Config.apiEndpoint)/api/books/sync")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SyncError.deleteFailed
        }
        
        print("✅ Deleted book from cloud")
    }
    
    // ============================================
    // HELPERS
    // ============================================
    
    private func extractGoogleBooksId(from bookId: String) -> String? {
        // If book ID starts with "google_", extract the Google Books ID
        if bookId.hasPrefix("google_") {
            return String(bookId.dropFirst(7))
        }
        return nil
    }
}

// ============================================
// MARK: - Errors
// ============================================

enum SyncError: LocalizedError {
    case notAuthenticated
    case syncFailed
    case fetchFailed
    case updateFailed
    case deleteFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to sync your books"
        case .syncFailed:
            return "Failed to sync books to cloud"
        case .fetchFailed:
            return "Failed to fetch books from cloud"
        case .updateFailed:
            return "Failed to update book"
        case .deleteFailed:
            return "Failed to delete book"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}
