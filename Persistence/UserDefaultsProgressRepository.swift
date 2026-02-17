//
//  UserDefaultsProgressRepository.swift
//  BookCompanion
//
//  Created by Shree on 01/02/2026.
//
import Foundation

final class UserDefaultsProgressRepository: ProgressRepository {

    private let defaults = UserDefaults.standard
    private let keyPrefix = "reading_progress_"

    func loadProgress(for bookId: String) -> ReadingProgress? {
        let key = keyPrefix + bookId

        guard
            let data = defaults.data(forKey: key),
            let progress = try? JSONDecoder().decode(ReadingProgress.self, from: data)
        else {
            return nil
        }

        return progress
    }

    func saveProgress(_ progress: ReadingProgress) {
        let key = keyPrefix + progress.bookId.uuidString

        guard let data = try? JSONEncoder().encode(progress) else {
            return
        }

        defaults.set(data, forKey: key)
    }
}

