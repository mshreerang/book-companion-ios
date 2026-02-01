//
//  SummaryGenerating.swift
//  BookCompanion
//
//  Created by Shree on 31/01/2026.
//
import Foundation

protocol SummaryGenerating {
    func generateSummary(
        book: Book,
        chapter: Int
    ) async throws -> BookSummary

    func generateCharacters(
        book: Book,
        chapter: Int
    ) async throws -> [BookCharacter]
}

