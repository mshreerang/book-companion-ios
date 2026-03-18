//
//  Book.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
import Foundation

// MARK: - BookType
// Drives prompt branching across summary, characters, and character chat.
// Detected once at search time (Google Books categories + AI sniper fallback)
// and stored permanently with the book.

enum BookType: String, Codable, CaseIterable {
    case fiction        = "fiction"        // novels, stories — default
    case autobiography  = "autobiography"  // author's own story (Becoming, Open)
    case biography      = "biography"      // subject's story told by author (Titan, Steve Jobs)
    case selfHelp       = "self_help"      // advice, frameworks (Atomic Habits, 7 Habits)
    case practical      = "practical"      // reference, how-to (What to Expect, cookbooks)

    // Display name for UI
    var displayName: String {
        switch self {
        case .fiction:       return "Fiction"
        case .autobiography: return "Autobiography"
        case .biography:     return "Biography"
        case .selfHelp:      return "Self-Help"
        case .practical:     return "Practical"
        }
    }

    // Whether this book type supports character chat
    // Practical books (reference/how-to) don't have meaningful characters to chat with
    // All book types support character chat:
    // - fiction: fictional characters
    // - autobiography/biography: real people
    // - selfHelp: author as expert guide
    // - practical: author as expert guide, topic-aware
    var supportsCharacterChat: Bool { true }

    // Whether summaries should be concept-based rather than plot-based
    var isNonFiction: Bool {
        self != .fiction
    }
}

struct Book: Identifiable, Codable {
    let id: UUID
    let title: String
    let author: String
    let language: Language
    let totalChapters: Int
    let pageCount: Int?
    let coverImageURL: String?
    let createdAt: Date

    // Book type — drives prompt branching (default: fiction for backwards compat)
    var bookType: BookType

    // Series tracking (optional — nil for standalone books)
    var seriesId: UUID?
    var seriesPosition: Int?
    var seriesName: String?      // display only — canonical name lives in series table

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

    var pagesInfo: String? {
        guard let pages = pageCount else { return nil }
        return "\(pages) pages"
    }

    // Progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard let progress = readingProgress else { return 0.0 }
        guard totalChapters > 0 else { return 0.0 }
        return Double(progress.chapter) / Double(totalChapters)
    }

    // Is book completed?
    var isCompleted: Bool {
        guard let progress = readingProgress else { return false }
        return progress.chapter >= totalChapters
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, title, author, language, totalChapters, pageCount, coverImageURL, createdAt
        case bookType
        case seriesId, seriesPosition, seriesName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id            = try container.decode(UUID.self,     forKey: .id)
        title         = try container.decode(String.self,   forKey: .title)
        author        = try container.decode(String.self,   forKey: .author)
        language      = try container.decode(Language.self, forKey: .language)
        totalChapters = try container.decode(Int.self,      forKey: .totalChapters)
        pageCount     = try container.decodeIfPresent(Int.self,    forKey: .pageCount)
        coverImageURL = try container.decodeIfPresent(String.self, forKey: .coverImageURL)
        createdAt     = try container.decode(Date.self,     forKey: .createdAt)
        // Default to .fiction for existing books that predate this field
        bookType      = try container.decodeIfPresent(BookType.self, forKey: .bookType) ?? .fiction
        seriesId      = try container.decodeIfPresent(UUID.self,   forKey: .seriesId)
        seriesPosition = try container.decodeIfPresent(Int.self,   forKey: .seriesPosition)
        seriesName    = try container.decodeIfPresent(String.self, forKey: .seriesName)
        readingProgress = nil
    }

    init(
        id: UUID,
        title: String,
        author: String,
        language: Language,
        totalChapters: Int,
        pageCount: Int? = nil,
        coverImageURL: String? = nil,
        createdAt: Date,
        bookType: BookType = .fiction,
        seriesId: UUID? = nil,
        seriesPosition: Int? = nil,
        seriesName: String? = nil,
        readingProgress: ReadingProgress? = nil
    ) {
        self.id            = id
        self.title         = title
        self.author        = author
        self.language      = language
        self.totalChapters = totalChapters
        self.pageCount     = pageCount
        self.coverImageURL = coverImageURL
        self.createdAt     = createdAt
        self.bookType      = bookType
        self.seriesId      = seriesId
        self.seriesPosition = seriesPosition
        self.seriesName    = seriesName
        self.readingProgress = readingProgress
    }
}
