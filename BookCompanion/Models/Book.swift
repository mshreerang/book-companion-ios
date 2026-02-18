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
    
    // Reading progress (loaded separately, not stored in Book)
    // This is transient and managed by BookManager
    var readingProgress: ReadingProgress?
    
    // Computed property for display
    var displayInfo: String {
        "\(title) by \(author)"
    }
    
    var chaptersInfo: String {
        "\(totalChapters) chapters"
    }
    
    // Progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard let progress = readingProgress else {
            return 0.0
        }
        guard totalChapters > 0 else {
            return 0.0
        }
        return Double(progress.chapter) / Double(totalChapters)
    }
    
    // Is book completed?
    var isCompleted: Bool {
        guard let progress = readingProgress else {
            return false
        }
        return progress.chapter >= totalChapters
    }
    
    // MARK: - Codable
    
    // Custom coding keys to exclude readingProgress from encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id, title, author, language, totalChapters, coverImageURL, createdAt
    }
    
    // Custom decoder to ensure readingProgress is properly initialized
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        author = try container.decode(String.self, forKey: .author)
        language = try container.decode(Language.self, forKey: .language)
        totalChapters = try container.decode(Int.self, forKey: .totalChapters)
        coverImageURL = try container.decodeIfPresent(String.self, forKey: .coverImageURL)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Initialize readingProgress as nil - will be loaded by BookManager
        readingProgress = nil
    }
    
    // Standard init for creating new books
    init(
        id: UUID,
        title: String,
        author: String,
        language: Language,
        totalChapters: Int,
        coverImageURL: String? = nil,
        createdAt: Date,
        readingProgress: ReadingProgress? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.language = language
        self.totalChapters = totalChapters
        self.coverImageURL = coverImageURL
        self.createdAt = createdAt
        self.readingProgress = readingProgress
    }
}
