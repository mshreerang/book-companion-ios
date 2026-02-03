//
//  MockSummaryGenerator.swift
//  BookCompanion
//
//  Created by Shree on 31/01/2026.
//
import Foundation

final class MockSummaryGenerator: SummaryGenerator {

    func generateSummary(
        book: Book,
        chapter: Int,
        language: Language
    ) async throws -> BookSummary {

        BookSummary(
            id: UUID(),
            bookId: book.id,
            chapter: chapter,
            progressId: UUID(),
            content: """
            Summary of "\(book.title)" 
            Safe up to chapter \(chapter).
            Language: \(language.displayName).
            (Generated at \(Date()))
            """,
            language: language,
            generatedAt: Date()
        )
    }

    func generateCharacters(
        book: Book,
        chapter: Int,
        language: Language
    ) async throws -> [BookCharacter] {
        []
    }
}
