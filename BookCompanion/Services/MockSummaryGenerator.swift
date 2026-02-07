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
        language: Language,
        length: SummaryLength  
    ) async throws -> BookSummary {

        let content: String
        
        switch length {
        case .short:
            content = """
            Summary of "\(book.title)" 
            Safe up to chapter \(chapter).
            Language: \(language.displayName).
            Length: Short
            (Generated at \(Date()))
            """
        case .medium:
            content = """
            Summary of "\(book.title)" 
            Safe up to chapter \(chapter).
            Language: \(language.displayName).
            Length: Medium
            
            This is a more detailed summary with additional paragraphs.
            It provides more context and depth about the story so far.
            
            (Generated at \(Date()))
            """
        }
        
        return BookSummary(
            id: UUID(),
            bookId: book.id,
            chapter: chapter,
            progressId: UUID(),
            content: content,
            language: language,
            length: length,  // ✅ Include length
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
