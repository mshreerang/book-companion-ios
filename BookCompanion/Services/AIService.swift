//
//  AIService.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
import Foundation
import Combine

struct AIService {

static func generateSummary(
book:Book,
chapter:Int
    )async throws ->BookSummary {
// Stubbed for now
return BookSummary(
            id:UUID(),
            bookId: book.id,
            progressId:UUID(),
            content:"This is a placeholder summary.",
            language: book.language,
            generatedAt:Date()
        )
    }

static func generateCharacters(
book:BookCharacter,
chapter:Int
    )async throws -> [BookCharacter] {
return []
    }
}


