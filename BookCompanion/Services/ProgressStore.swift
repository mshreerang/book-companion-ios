//
//  ProgressStore.swift
//  BookCompanion
//
//  Created by Shree on 31/01/2026.
//
import Foundation

final class ProgressStore {

    static let shared = ProgressStore()

    private let key = "reading_progress_store"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // Save or update progress for a book
    func save(_ progress: ReadingProgress) {
        var all = loadAll()
        all[progress.bookId.uuidString] = progress

        if let data = try? encoder.encode(all) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // Load progress for a specific book
    func load(bookId: UUID) -> ReadingProgress? {
        loadAll()[bookId.uuidString]
    }

    // Load everything (internal)
    private func loadAll() -> [String: ReadingProgress] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? decoder.decode([String: ReadingProgress].self, from: data)
        else {
            return [:]
        }
        return decoded
    }
}

