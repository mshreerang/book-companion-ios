//
//  SummaryRepository.swift
//  BookCompanion
//
//  Created by Shree on 01/02/2026.
//
import Foundation

protocol SummaryRepository {
    func loadSummary(
        bookId: UUID,
        chapter: Int,
        language: Language,
        length: SummaryLength
    ) -> BookSummary?

    func saveSummary(_ summary: BookSummary)
    
    func loadCharacters(
        bookId: UUID,
        chapter: Int,
        language: Language,
        length: SummaryLength  
    ) -> [BookCharacter]?
    
    func saveCharacters(
        _ characters: [BookCharacter],
        bookId: UUID,
        chapter: Int,
        language: Language,
        length: SummaryLength
    )
}
