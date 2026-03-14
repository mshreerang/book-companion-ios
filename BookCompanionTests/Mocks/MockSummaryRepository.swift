// MockSummaryRepository.swift
// BookCompanionTests — Shared Mock Infrastructure
//
// In-memory implementation of SummaryRepository.
// Use in setUp(); state resets automatically when the instance is recreated.

import Foundation
@testable import BookCompanion

final class MockSummaryRepository: SummaryRepository {

    // MARK: - Storage

    private var summaries: [String: BookSummary] = [:]
    private var characters: [String: [BookCharacter]] = [:]

    // MARK: - Call Tracking

    private(set) var saveSummaryCalled = false
    private(set) var saveCharactersCalled = false
    private(set) var loadSummaryCallCount = 0
    private(set) var loadCharactersCallCount = 0

    // MARK: - SummaryRepository

    func loadSummary(bookId: UUID, chapter: Int, language: Language, length: SummaryLength) -> BookSummary? {
        loadSummaryCallCount += 1
        return summaries[key(bookId: bookId, chapter: chapter, language: language, length: length)]
    }

    func saveSummary(_ summary: BookSummary) {
        saveSummaryCalled = true
        let k = key(bookId: summary.bookId, chapter: summary.chapter,
                    language: summary.language, length: summary.length)
        summaries[k] = summary
    }

    func loadCharacters(bookId: UUID, chapter: Int, language: Language, length: SummaryLength) -> [BookCharacter]? {
        loadCharactersCallCount += 1
        return characters[key(bookId: bookId, chapter: chapter, language: language, length: length)]
    }

    func saveCharacters(_ chars: [BookCharacter], bookId: UUID, chapter: Int, language: Language, length: SummaryLength) {
        saveCharactersCalled = true
        characters[key(bookId: bookId, chapter: chapter, language: language, length: length)] = chars
    }

    // MARK: - Helpers

    private func key(bookId: UUID, chapter: Int, language: Language, length: SummaryLength) -> String {
        "\(bookId.uuidString)_\(chapter)_\(language.rawValue)_\(length.rawValue)"
    }

    func seedSummary(_ summary: BookSummary) {
        let k = key(bookId: summary.bookId, chapter: summary.chapter,
                    language: summary.language, length: summary.length)
        summaries[k] = summary
    }

    func seedCharacters(_ chars: [BookCharacter], bookId: UUID, chapter: Int,
                        language: Language, length: SummaryLength) {
        characters[key(bookId: bookId, chapter: chapter, language: language, length: length)] = chars
    }
}
