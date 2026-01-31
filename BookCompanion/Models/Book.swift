//
//  Book.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
import Foundation

struct Book: Identifiable {
    let id: UUID
    let title: String
    let author: String
    let language: Language
    let createdAt: Date
}

