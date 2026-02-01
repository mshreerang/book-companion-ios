//
//  ReadingProgress.swift
//  BookCompanion
//
//  Created by Shree on 31/01/2026.
//
import Foundation

struct ReadingProgress: Codable, Identifiable {
    let id: UUID
    let bookId: UUID
    let chapter: Int
    let language: Language
    let updatedAt: Date
}

