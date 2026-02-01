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
        language: Language
    ) -> BookSummary?

    func saveSummary(_ summary: BookSummary)
}

