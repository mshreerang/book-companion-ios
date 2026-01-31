//
//  BookSummary.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
import Foundation

struct BookSummary:Identifiable {
//struct BookSummary_DO_NOT_USE: Identifiable {
let id: UUID
let bookId: UUID
let progressId: UUID
let content: String
let language: Language
let generatedAt: Date
}

