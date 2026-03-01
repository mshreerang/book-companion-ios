//
//  BookManager.swift
//  BookCompanion
//
//  Updated by Shree on 23/02/2026.
//

import Foundation
import Combine
import SwiftUI

final class BookManager: ObservableObject {
    
    @Published private(set) var books: [Book] = []
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    
    private let defaults = UserDefaults.standard
    private let key = "user_books"
    private let progressKeyPrefix = "reading_progress_"
    private let syncService = BookSyncService.shared
    
    init() {
        loadBooks()
        reloadProgress()
    }
    
    // ============================================
    // MARK: - Cloud Sync
    // ============================================
    
    /// Fetch books from cloud and merge with local
    func syncFromCloud() async {
        guard AuthManager.shared.isSignedIn else {
            print("⚠️ User not signed in - skipping sync")
            return
        }
        
        await MainActor.run { isSyncing = true }
        
        do {
            // ✅ Use detached task so it continues even if view disappears
            let cloudBooks = try await withCheckedThrowingContinuation { continuation in
                Task.detached {
                    do {
                        let books = try await self.syncService.fetchBooksFromCloud()
                        continuation.resume(returning: books)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            await MainActor.run {
                // Merge strategy: Cloud is source of truth
                // But keep any local books not in cloud
                var mergedBooks: [Book] = []
                var cloudBookIds = Set<UUID>()
                
                // Add all cloud books
                for cloudBook in cloudBooks {
                    cloudBookIds.insert(cloudBook.id)
                    
                    // Check if we have local progress for this book
                    if let localProgress = loadProgress(for: cloudBook.id) {
                        var updatedBook = cloudBook
                        updatedBook.readingProgress = localProgress
                        mergedBooks.append(updatedBook)
                    } else {
                        mergedBooks.append(cloudBook)
                    }
                }
                
                // Add local-only books (not in cloud yet)
                for localBook in books {
                    if !cloudBookIds.contains(localBook.id) {
                        mergedBooks.append(localBook)
                    }
                }
                
                self.books = mergedBooks
                self.lastSyncDate = Date()
                self.saveBooks()
                
                print("✅ Synced from cloud: \(cloudBooks.count) cloud books, \(mergedBooks.count) total")
            }
            
        } catch {
            // ✅ Ignore "cancelled" errors (view disappeared during sync)
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == -999 {
                print("ℹ️ Sync cancelled (view dismissed)")
            } else {
                print("❌ Sync from cloud failed: \(error)")
            }
        }
        
        await MainActor.run { isSyncing = false }
    }
    
    /// Upload all books to cloud
    func syncToCloud() async {
        guard AuthManager.shared.isSignedIn else {
            print("⚠️ User not signed in - skipping sync")
            return
        }
        
        guard !books.isEmpty else {
            print("ℹ️ No books to sync")
            return
        }
        
        await MainActor.run { isSyncing = true }
        
        do {
            try await syncService.syncBooksToCloud(books)
            await MainActor.run {
                lastSyncDate = Date()
            }
            print("✅ Synced \(books.count) books to cloud")
        } catch {
            print("❌ Sync to cloud failed: \(error)")
        }
        
        await MainActor.run { isSyncing = false }
    }
    
    // ============================================
    // MARK: - Public Methods
    // ============================================
    
    func addBook(
        title: String,
        author: String,
        language: Language,
        totalChapters: Int,
        pageCount: Int? = nil,
        coverImageURL: String? = nil
    ) {
        let book = Book(
            id: UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            language: language,
            totalChapters: totalChapters,
            pageCount: pageCount,
            coverImageURL: coverImageURL,
            createdAt: Date()
        )
        
        books.append(book)
        saveBooks()
        
        // ✅ Sync to cloud in background
        Task {
            await syncToCloud()
        }
    }
    
    func deleteBook(_ book: Book) {
        books.removeAll { $0.id == book.id }
        deleteProgress(for: book.id)
        saveBooks()
        
        // ✅ Delete from cloud in background
        Task {
            do {
                try await syncService.deleteBook(book.id)
                print("✅ Deleted book from cloud")
            } catch {
                print("❌ Failed to delete from cloud: \(error)")
            }
        }
    }
    
    func deleteBooks(at offsets: IndexSet) {
        let booksToDelete = offsets.map { books[$0] }
        
        // Delete progress for each book being removed
        for index in offsets {
            let book = books[index]
            deleteProgress(for: book.id)
        }
        
        books.remove(atOffsets: offsets)
        saveBooks()
        
        // ✅ Delete from cloud in background
        Task {
            for book in booksToDelete {
                do {
                    try await syncService.deleteBook(book.id)
                } catch {
                    print("❌ Failed to delete \(book.title) from cloud: \(error)")
                }
            }
        }
    }
    
    // ============================================
    // MARK: - Progress Management
    // ============================================
    
    func reloadProgress() {
        for index in books.indices {
            if let progress = loadProgress(for: books[index].id) {
                books[index].readingProgress = progress
            }
        }
    }
    
    func saveProgress(_ progress: ReadingProgress, for bookId: UUID) {
        let key = progressKey(for: bookId)
        if let encoded = try? JSONEncoder().encode(progress) {
            defaults.set(encoded, forKey: key)
        }
        
        // Update the book's progress in memory
        if let index = books.firstIndex(where: { $0.id == bookId }) {
            books[index].readingProgress = progress
            
            // ✅ Sync progress to cloud in background
            let book = books[index]
            Task {
                do {
                    try await syncService.updateBook(book)
                    print("✅ Synced progress for \(book.title)")
                } catch {
                    print("❌ Failed to sync progress: \(error)")
                }
            }
        }
    }
    
    func loadProgress(for bookId: UUID) -> ReadingProgress? {
        let key = progressKey(for: bookId)
        guard let data = defaults.data(forKey: key),
              let progress = try? JSONDecoder().decode(ReadingProgress.self, from: data) else {
            return nil
        }
        return progress
    }
    
    private func deleteProgress(for bookId: UUID) {
        let key = progressKey(for: bookId)
        defaults.removeObject(forKey: key)
    }
    
    private func progressKey(for bookId: UUID) -> String {
        "\(progressKeyPrefix)\(bookId.uuidString)"
    }
    
    // ============================================
    // MARK: - Private Methods
    // ============================================
    
    private func loadBooks() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Book].self, from: data) else {
            // First launch - no books yet
            books = []
            return
        }
        books = decoded
    }
    
    private func saveBooks() {
        if let encoded = try? JSONEncoder().encode(books) {
            defaults.set(encoded, forKey: key)
        }
    }
}
