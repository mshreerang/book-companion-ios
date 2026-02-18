//
//  AccessibilityIdentifiers.swift
//  BookCompanion
//
//  Created on 15/02/2026.
//
import SwiftUI

// MARK: - Accessibility Helper Extensions

extension View {
    /// Make button accessible with label and hint
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Make image accessible
    func accessibleImage(label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isImage)
    }
    
    /// Make progress indicator accessible
    func accessibleProgress(label: String, value: Double) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue("\(Int(value * 100))% complete")
    }
    
    /// Hide decorative elements from VoiceOver
    func decorative() -> some View {
        self.accessibilityHidden(true)
    }
}

// MARK: - Accessibility Labels

enum A11y {
    
    // MARK: - Library
    enum Library {
        static let title = "My Library"
        static let addButton = "Add book"
        static let addButtonHint = "Search for a new book to add to your library"
        static let settingsButton = "Settings"
        static let settingsButtonHint = "Open app settings"
        static let searchButton = "Search and add books"
        static func bookRow(title: String, author: String) -> String {
            "\(title) by \(author)"
        }
        static func bookProgress(chapter: Int, total: Int, percentage: Int) -> String {
            "Chapter \(chapter) of \(total), \(percentage)% complete"
        }
    }
    
    // MARK: - Book Details
    enum BookDetails {
        static let chapterStepper = "Chapter selection"
        static func chapterValue(chapter: Int, total: Int) -> String {
            "Chapter \(chapter) of \(total)"
        }
        static let languageSelector = "Summary language"
        static let lengthSelector = "Summary length"
        static let generateButton = "Generate summary"
        static let generateHint = "Create AI-powered summary for selected chapter"
    }
    
    // MARK: - Summary
    enum Summary {
        static let title = "Story So Far"
        static let listenButton = "Listen to summary"
        static let stopButton = "Stop listening"
        static let charactersButton = "View characters"
        static let regenerateButton = "Regenerate summary"
        static let regenerateHint = "Create a new summary for this chapter"
        static func safeBadge(chapter: Int) -> String {
            "Spoiler-free up to chapter \(chapter)"
        }
        static let cachedBadge = "Previously generated summary"
    }
    
    // MARK: - Characters
    enum Characters {
        static let title = "Characters"
        static func characterCard(name: String, description: String) -> String {
            "\(name). \(description)"
        }
    }
    
    // MARK: - Search
    enum Search {
        static let searchField = "Search books"
        static let searchFieldHint = "Enter book title or author name"
        static let searchButton = "Search online"
        static let clearButton = "Clear search"
        static let cancelButton = "Cancel"
        static func onlineResult(title: String, author: String) -> String {
            "\(title) by \(author)"
        }
        static let addBookButton = "Add to library"
    }
    
    // MARK: - Settings
    enum Settings {
        static let title = "Settings"
        static let aiToggle = "AI-powered summaries"
        static func aiToggleHint(enabled: Bool) -> String {
            enabled ? "Disable to use offline mode only" : "Enable to use AI features"
        }
        static let clearCovers = "Clear all book covers"
        static let clearCoversHint = "Delete cached covers to free up space"
    }
}
