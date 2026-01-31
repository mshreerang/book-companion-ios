//
//  MockSummaryGenerator.swift
//  BookCompanion
//
//  Created by Shree on 31/01/2026.
//
import Foundation

struct MockSummaryGenerator: SummaryGenerating {

    func generateSummary(
        book: Book,
        chapter: Int
    ) async throws -> BookSummary {

        BookSummary(
            id: UUID(),
            bookId: book.id,
            progressId: UUID(),
            content: """
            Up to chapter \(chapter), the story establishes the central themes and introduces the main characters.

            The narrative explores memory, identity, and relationships, setting the stage for deeper conflicts later in the book.
            """,
            language: book.language,
            generatedAt: Date()
        )
    }

    func generateCharacters(
        book: Book,
        chapter: Int
    ) async throws -> [BookCharacter] {

        let progressId = UUID()

        return [
            BookCharacter(
                id: UUID(),
                bookId: book.id,
                progressId: progressId,
                name: "Ila",
                description: "A free-spirited woman whose life choices challenge traditional expectations.",
                relationships: "Connected to the narrator through childhood memories.",
                language: book.language,
                generatedAt: Date()
            ),
            BookCharacter(
                id: UUID(),
                bookId: book.id,
                progressId: progressId,
                name: "Tridib",
                description: "An intellectual influence who shapes the narrator’s imagination and worldview.",
                relationships: "Cousin and mentor figure.",
                language: book.language,
                generatedAt: Date()
            ),
            BookCharacter(
                id: UUID(),
                bookId: book.id,
                progressId: progressId,
                name: "Tha'mma",
                description: "A strong-willed grandmother deeply shaped by ideas of nationhood and family honor.",
                relationships: "Grandmother of the narrator.",
                language: book.language,
                generatedAt: Date()
            )
        ]
    }
}

