//
//  BookManager.swift
//  BookCompanion
//
//  Created by Shree on 06/02/2026.
//

import Foundation
import Combine
import SwiftUI

final class BookManager: ObservableObject {
    
    @Published private(set) var books: [Book] = []
    
    private let defaults = UserDefaults.standard
    private let key = "user_books"
    private let progressKeyPrefix = "reading_progress_"
    
    init() {
        loadBooks()
        reloadProgress()
    }
    
    // MARK: - Public Methods
    
    func addBook(
        title: String,
        author: String,
        language: Language,
        totalChapters: Int,
        coverImageURL: String? = nil
    ) {
        let book = Book(
            id: UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            language: language,
            totalChapters: totalChapters,
            coverImageURL: coverImageURL,
            createdAt: Date()
        )
        
        books.append(book)
        saveBooks()
    }
    
    func deleteBook(_ book: Book) {
        books.removeAll { $0.id == book.id }
        // Also delete progress for this book
        deleteProgress(for: book.id)
        saveBooks()
    }
    
    func deleteBooks(at offsets: IndexSet) {
        // Delete progress for each book being removed
        for index in offsets {
            let book = books[index]
            deleteProgress(for: book.id)
        }
        books.remove(atOffsets: offsets)
        saveBooks()
    }
    
    // MARK: - Progress Management
    
    func reloadProgress() {
        // Load progress for each book
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
    
    // MARK: - Private Methods
    
    private func loadBooks() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Book].self, from: data) else {
            // First launch - load sample books
            books = MockData.books
            saveBooks()
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
