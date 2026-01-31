//
//  Character.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
import Foundation

struct BookCharacter:Identifiable {
let id: UUID
let bookId: UUID
let progressId: UUID
let name: String
let description: String
let relationships: String?
let language: Language
let generatedAt: Date
}
