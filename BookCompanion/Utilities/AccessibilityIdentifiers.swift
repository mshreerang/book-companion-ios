//
//  AccessibilityIdentifiers.swift
//  BookCompanion
//
//  Created on 15/02/2026.
//  Updated: "Chat with Characters" rename propagated,
//           chatButton + chatHint added to BookDetails,
//           Library addButton hint updated to match current UX.
//

import SwiftUI

// MARK: - Accessibility Helper Extensions

extension View {
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }

    func accessibleImage(label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isImage)
    }

    func accessibleProgress(label: String, value: Double) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue("\(Int(value * 100))% complete")
    }

    func decorative() -> some View {
        self.accessibilityHidden(true)
    }
}

// MARK: - Accessibility Labels

enum A11y {

    // MARK: - Library

    enum Library {
        static let title             = "My Library"
        static let addButton         = "Add book"
        // Updated: reflects that the button opens a search, not just adds
        static let addButtonHint     = "Search online for a book to add to your library"
        static let settingsButton    = "Settings"
        static let settingsButtonHint = "Open app settings"
        static let searchButton      = "Search and add books"

        static func bookRow(title: String, author: String) -> String {
            "\(title) by \(author)"
        }
        static func bookProgress(chapter: Int, total: Int, percentage: Int) -> String {
            "Chapter \(chapter) of \(total), \(percentage)% complete"
        }
    }

    // MARK: - Book Details

    enum BookDetails {
        static let chapterStepper  = "Chapter selection"

        static func chapterValue(chapter: Int, total: Int) -> String {
            "Chapter \(chapter) of \(total)"
        }

        static let languageSelector = "Summary language"
        static let lengthSelector   = "Summary length"

        // Generate Summary action
        static let generateButton   = "Generate summary"
        static let generateHint     = "Create an AI-powered summary for the selected chapter"

        // Chat with Characters action — added to match the renamed feature
        static let chatButton       = "Chat with characters"
        static let chatHint         = "Talk to characters from this chapter. Spoiler-safe up to your current chapter."
    }

    // MARK: - Summary

    enum Summary {
        static let title            = "Story So Far"
        static let listenButton     = "Listen to summary"
        static let stopButton       = "Stop listening"
        // Updated: renamed from "View characters" to match feature rename
        static let charactersButton = "Chat with characters"
        static let regenerateButton = "Regenerate summary"
        static let regenerateHint   = "Create a new summary for this chapter"

        static func safeBadge(chapter: Int) -> String {
            "Spoiler-free up to chapter \(chapter)"
        }
        static let cachedBadge      = "Previously generated summary"
        static let seriesBadge      = "Summary includes context from earlier books in the series"
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
        static let searchField      = "Search books"
        static let searchFieldHint  = "Enter a book title or author name"
        static let searchButton     = "Search online"
        static let clearButton      = "Clear search"
        static let cancelButton     = "Cancel"

        static func onlineResult(title: String, author: String) -> String {
            "\(title) by \(author)"
        }
        static let addBookButton    = "Add to library"
    }

    // MARK: - Settings

    enum Settings {
        static let title            = "Settings"
        static let aiToggle         = "AI-powered summaries"

        static func aiToggleHint(enabled: Bool) -> String {
            enabled
                ? "Disable to use offline mode only"
                : "Enable to use AI-powered summaries and character chat"
        }

        static let clearCovers      = "Clear all book covers"
        static let clearCoversHint  = "Delete cached covers to free up storage space"
    }
}
