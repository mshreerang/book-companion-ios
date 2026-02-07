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
    
    init() {
        loadBooks()
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
        saveBooks()
    }
    
    func deleteBooks(at offsets: IndexSet) {
        books.remove(atOffsets: offsets)
        saveBooks()
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
