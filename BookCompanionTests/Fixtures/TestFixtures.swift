// TestFixtures.swift
// BookCompanionTests — Shared Fixtures
//
// Factory methods for common test objects.
// All IDs are deterministic so tests can make reliable assertions.

import Foundation
@testable import BookCompanion

enum TestFixtures {

    // MARK: - Books

    static func makeBook(
        id: UUID = UUID(uuidString: "A1B2C3D4-0000-0000-0000-000000000001")!,
        title: String = "The Great Gatsby",
        author: String = "F. Scott Fitzgerald",
        language: Language = .english,
        totalChapters: Int = 9,
        coverImageURL: String? = nil
    ) -> Book {
        Book(
            id: id,
            title: title,
            author: author,
            language: language,
            totalChapters: totalChapters,
            pageCount: nil,
            coverImageURL: coverImageURL,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    static func makeHindiBook() -> Book {
        makeBook(title: "गोदान", author: "मुंशी प्रेमचंद", language: .hindi, totalChapters: 30)
    }

    static func makeMarathiBook() -> Book {
        makeBook(title: "कोसला", author: "भालचंद्र नेमाडे", language: .marathi, totalChapters: 20)
    }

    // MARK: - Reading Progress

    static func makeProgress(
        bookId: UUID = UUID(uuidString: "A1B2C3D4-0000-0000-0000-000000000001")!,
        chapter: Int = 3,
        language: Language = .english
    ) -> ReadingProgress {
        ReadingProgress(
            id: UUID(),
            bookId: bookId,
            chapter: chapter,
            language: language,
            updatedAt: Date()
        )
    }

    // MARK: - Summaries

    static func makeSummary(
        bookId: UUID = UUID(uuidString: "A1B2C3D4-0000-0000-0000-000000000001")!,
        chapter: Int = 3,
        language: Language = .english,
        length: SummaryLength = .short,
        content: String = "Nick meets Gatsby at a party."
    ) -> BookSummary {
        BookSummary(
            id: UUID(),
            bookId: bookId,
            chapter: chapter,
            progressId: UUID(),
            content: content,
            language: language,
            length: length,
            generatedAt: Date()
        )
    }

    // MARK: - Characters

    static func makeCharacter(
        bookId: UUID = UUID(uuidString: "A1B2C3D4-0000-0000-0000-000000000001")!,
        name: String = "Jay Gatsby",
        description: String = "Mysterious wealthy neighbour",
        relationships: String? = "In love with Daisy",
        language: Language = .english
    ) -> BookCharacter {
        BookCharacter(
            id: UUID(),
            bookId: bookId,
            progressId: UUID(),
            name: name,
            description: description,
            relationships: relationships,
            language: language,
            generatedAt: Date()
        )
    }

    static func makeCharacterList(count: Int = 7, bookId: UUID = UUID()) -> [BookCharacter] {
        (0..<count).map { i in
            makeCharacter(bookId: bookId, name: "Character \(i)", description: "Description \(i)")
        }
    }

    // MARK: - Chat Messages

    static func makeUserMessage(_ text: String = "Hello") -> CharacterChatMessage {
        .userMessage(text)
    }

    static func makeCharacterMessage(_ text: String = "I remember it well.") -> CharacterChatMessage {
        CharacterChatMessage(role: .character, content: text)
    }

    // MARK: - CharacterCard

    static func makeCharacterCard(
        id: String = "gatsby",
        fullName: String = "Jay Gatsby"
    ) -> CharacterCard {
        CharacterCard(
            id: id,
            fullName: fullName,
            description: "A mysterious millionaire",
            relationships: "In love with Daisy Buchanan",
            currentSituation: "Throwing lavish parties",
            role: "Protagonist"
        )
    }
}
