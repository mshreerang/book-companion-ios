//
//  Summary.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
import Foundation

struct Summary:Identifiable {
let id: UUID
let bookId: UUID
let progressId: UUID
let content: String
let language: Language
let generatedAt: Date
}

