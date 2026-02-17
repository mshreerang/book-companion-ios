//
//  Book.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
import Foundation

struct Book: Identifiable, Codable {
    let id: UUID
    let title: String
    let author: String
    let language: Language
    let totalChapters: Int
    let coverImageURL: String?
    let createdAt: Date
    
    // Computed property for display
    var displayInfo: String {
        "\(title) by \(author)"
    }
    
    var chaptersInfo: String {
        "\(totalChapters) chapters"
    }
}
