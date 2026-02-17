//
//  MockSummaryGenerator.swift
//  BookCompanion
//
//  Created by Shree on 31/01/2026.
//
import Foundation

final class MockSummaryGenerator: SummaryGenerator {
    
    // ✅ Add repository to check cache
    private let repository: SummaryRepository
    
    init(repository: SummaryRepository = UserDefaultsSummaryRepository()) {
        self.repository = repository
    }

    func generateSummary(
        book: Book,
        chapter: Int,
        language: Language,
        length: SummaryLength
    ) async throws -> BookSummary {
        
        // ✅ CHECK CACHE FIRST (from AI mode)
        if let cachedSummary = repository.loadSummary(
            bookId: book.id,
            chapter: chapter,
            language: language,
            length: length
        ) {
            print("✅ Offline mode: Using cached AI summary for Chapter \(chapter)")
            return cachedSummary
        }
        
        // ✅ If no cache, generate mock data
        print("⚠️ Offline mode: No cached summary, showing mock data for Chapter \(chapter)")

        let content: String
        
        switch length {
        case .short:
            content = """
            📖 Offline Mock Summary
            
            This is sample data for "\(book.title)" up to chapter \(chapter).
            
            Enable AI mode and generate a real summary to see actual content from the book.
            
            Language: \(language.displayName)
            Length: Short
            """
        case .medium:
            content = """
            📖 Offline Mock Summary
            
            This is sample data for "\(book.title)" up to chapter \(chapter).
            
            To get real, AI-generated summaries with actual plot details and character information, enable AI mode in Settings and regenerate.
            
            This mock summary helps you test the app features without using AI credits.
            
            Language: \(language.displayName)
            Length: Medium
            
            (Generated in offline mode at \(Date().formatted()))
            """
        }
        
        return BookSummary(
            id: UUID(),
            bookId: book.id,
            chapter: chapter,
            progressId: UUID(),
            content: content,
            language: language,
            length: length,
            generatedAt: Date()
        )
    }

    func generateCharacters(
        book: Book,
        chapter: Int,
        language: Language
    ) async throws -> [BookCharacter] {
        
        // ✅ CHECK CACHE FIRST
        if let cachedCharacters = repository.loadCharacters(
            bookId: book.id,
            chapter: chapter,
            language: language,
            length: .medium  // Default length for characters
        ) {
            print("✅ Offline mode: Using cached AI characters for Chapter \(chapter)")
            return cachedCharacters
        }
        
        print("⚠️ Offline mode: No cached characters, showing empty list")
        return []
    }
}
