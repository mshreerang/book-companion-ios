//
//  BookSummary.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
import Foundation

struct BookSummary:Identifiable, Codable {
let id: UUID
let bookId: UUID
let chapter: Int
let progressId: UUID
let content: String
let language: Language
let length: SummaryLength 
let generatedAt: Date
}

