// MockSummaryGeneratorSpy.swift
// BookCompanionTests — Shared Mock Infrastructure
//
// Configurable spy for SummaryGenerator protocol.
// Default: returns a predictable BookSummary / [BookCharacter].
// Configure throwError to simulate failure paths.

import Foundation
@testable import BookCompanion

final class MockSummaryGeneratorSpy: SummaryGenerator {

    // MARK: - Configuration

    var summaryToReturn: BookSummary?
    var charactersToReturn: [BookCharacter] = []
    var throwError: Error?

    // Simulated async delay in nanoseconds (default 0 = synchronous)
    var delay: UInt64 = 0

    // MARK: - Call Tracking

    private(set) var generateSummaryCalled = false
    private(set) var generateCharactersCalled = false
    private(set) var lastBookPassed: Book?
    private(set) var lastChapterPassed: Int?
    private(set) var lastLanguagePassed: Language?
    private(set) var lastLengthPassed: SummaryLength?

    // MARK: - SummaryGenerator

    func generateSummary(book: Book, chapter: Int, language: Language, length: SummaryLength) async throws -> BookSummary {
        generateSummaryCalled = true
        lastBookPassed = book
        lastChapterPassed = chapter
        lastLanguagePassed = language
        lastLengthPassed = length

        if delay > 0 { try await Task.sleep(nanoseconds: delay) }
        if let err = throwError { throw err }

        return summaryToReturn ?? BookSummary(
            id: UUID(),
            bookId: book.id,
            chapter: chapter,
            progressId: UUID(),
            content: "Mock summary content for chapter \(chapter)",
            language: language,
            length: length,
            generatedAt: Date()
        )
    }

    func generateCharacters(book: Book, chapter: Int, language: Language) async throws -> [BookCharacter] {
        generateCharactersCalled = true
        lastBookPassed = book
        lastChapterPassed = chapter
        lastLanguagePassed = language

        if delay > 0 { try await Task.sleep(nanoseconds: delay) }
        if let err = throwError { throw err }

        return charactersToReturn
    }
}
