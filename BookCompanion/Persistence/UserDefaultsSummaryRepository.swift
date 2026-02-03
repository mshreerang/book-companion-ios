//
//  UserDefaultsSummaryRepository.swift
//  BookCompanion
//
//  Created by Shree on 01/02/2026.
//
import Foundation

final class UserDefaultsSummaryRepository: SummaryRepository {

    private let defaults = UserDefaults.standard
    private let keyPrefix = "book_summary_"

    func loadSummary(
        bookId: UUID,
        chapter: Int,
        language: Language
    ) -> BookSummary? {

        let key = makeKey(
            bookId: bookId,
            chapter: chapter,
            language: language
        )

        guard
            let data = defaults.data(forKey: key),
            let summary = try? JSONDecoder().decode(BookSummary.self, from: data)
        else {
            return nil
        }

        return summary
    }

    func saveSummary(_ summary: BookSummary) {
        let key = makeKey(
            bookId: summary.bookId,
            chapter: summary.chapter,
            language: summary.language
        )

        guard let data = try? JSONEncoder().encode(summary) else {
            return
        }

        defaults.set(data, forKey: key)
    }

    // MARK: - Helpers

    private func makeKey(
        bookId: UUID,
        chapter: Int,
        language: Language
    ) -> String {
        "\(keyPrefix)\(bookId.uuidString)_\(chapter)_\(language.rawValue)"
    }

    // No helper needed: BookSummary already contains `chapter`.
}
