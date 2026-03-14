//
//  SeriesDetector.swift
//  BookCompanion
//
//  Created for v1.1 series tracking feature.
//
//  Pure detection logic — no UI, no network calls.
//  Takes a BookSearchResult and returns a SeriesDetectionResult if a series is found.

import Foundation

// MARK: - SeriesDetectionResult

struct SeriesDetectionResult {
    let seriesName: String
    let position: Int
    let source: DetectionSource

    enum DetectionSource {
        case googleBooksMetadata   // from seriesName/seriesPosition in API response
        case titlePattern          // from regex on title string
    }
}

// MARK: - AuthorSeriesHint
// Returned when no series metadata is found but the author matches library books

struct AuthorSeriesHint {
    let matchingBooks: [Book]   // existing library books by same author
    let suggestedPosition: Int  // best guess at position (highest existing + 1)
}

// MARK: - SeriesDetector

enum SeriesDetector {

    // Regex patterns for title-based detection
    // Ordered by specificity — most specific first
    private static let titlePatterns: [(pattern: String, nameGroup: Int?, positionGroup: Int)] = [
        // "(Series Name, #N)" or "(Series Name #N)"  e.g. "Oathbringer (The Stormlight Archive, #3)"
        (#"\(([^)]+?),?\s*#(\d+)\)"#,          1, 2),
        // "Series Name: Book N"               e.g. "The Wheel of Time: Book 14"
        (#"^(.+?):\s*[Bb]ook\s+(\d+)"#,        1, 2),
        // "Title (Series Name Book N)"         e.g. "Dune (Dune Chronicles Book 1)"
        (#"\((.+?)\s+[Bb]ook\s+(\d+)\)"#,      1, 2),
        // "Series Name Book N"                 e.g. "Harry Potter Book 3"
        (#"^(.+?)\s+[Bb]ook\s+(\d+)$"#,        1, 2),
        // "(N of M)" — position only, no series name
        (#"\((\d+)\s+of\s+\d+\)"#,             nil, 1),
        // "Volume N" — position only
        (#"[Vv]olume\s+(\d+)"#,                nil, 1),
    ]

    // Word-to-number mapping for "Book One", "Book Two" etc
    private static let wordToNumber: [String: Int] = [
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10
    ]

    /// Attempt to detect series information from a BookSearchResult.
    /// Returns nil if no series is detected.
    static func detect(from result: BookSearchResult) -> SeriesDetectionResult? {

        // ── Priority 1: Backend metadata (Google Books or regex already run server-side) ──
        if let name = result.seriesName,
           let position = result.seriesPosition,
           !name.isEmpty,
           position > 0 {
            return SeriesDetectionResult(
                seriesName: normalise(name),
                position: position,
                source: .googleBooksMetadata
            )
        }

        // Position-only from backend (no name) — still useful
        if let position = result.seriesPosition, position > 0 {
            return SeriesDetectionResult(
                seriesName: "",   // empty — UI will prompt user to fill in
                position: position,
                source: .googleBooksMetadata
            )
        }

        // ── Priority 2: Client-side title pattern matching ───────────────────
        let titleToTest = result.title
        for (pattern, nameGroup, posGroup) in titlePatterns {
            if let detected = match(titleToTest, pattern: pattern, nameGroup: nameGroup, positionGroup: posGroup) {
                return detected
            }
        }

        return nil
    }

    /// Check if any books in the user's existing library share the same author.
    /// Used as Layer 2 heuristic when no series metadata is found.
    /// Returns a hint if matches found, nil otherwise.
    static func authorHint(for result: BookSearchResult, in library: [Book]) -> AuthorSeriesHint? {
        let searchAuthor = result.author.lowercased().trimmingCharacters(in: .whitespaces)
        guard !searchAuthor.isEmpty else { return nil }

        let matchingBooks = library.filter { book in
            book.author.lowercased().trimmingCharacters(in: .whitespaces)
                .contains(searchAuthor) ||
            searchAuthor.contains(book.author.lowercased().trimmingCharacters(in: .whitespaces))
        }

        guard !matchingBooks.isEmpty else { return nil }

        // Suggest next position = highest existing series position + 1
        let highestPosition = matchingBooks
            .compactMap { $0.seriesPosition }
            .max() ?? matchingBooks.count
        let suggestedPosition = highestPosition + 1

        return AuthorSeriesHint(
            matchingBooks: matchingBooks,
            suggestedPosition: suggestedPosition
        )
    }

    // MARK: - Helpers

    /// Normalise a series name for consistent storage.
    /// Strips trailing "Series", "Saga", "Trilogy" suffixes that add noise.
    private static func normalise(_ name: String) -> String {
        var cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let suffixes = [" Series", " Saga", " Trilogy", " Chronicles", " Duology"]
        for suffix in suffixes {
            if cleaned.hasSuffix(suffix) {
                cleaned = String(cleaned.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        return cleaned
    }

    /// Run a regex pattern against a title and return a SeriesDetectionResult if matched.
    /// nameGroup is optional — some patterns extract position only, with no series name capture group.
    private static func match(_ title: String, pattern: String, nameGroup: Int?, positionGroup: Int) -> SeriesDetectionResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)) else {
            return nil
        }

        // Extract position (required)
        guard let posRange = Range(match.range(at: positionGroup), in: title),
              let position = Int(title[posRange]),
              position > 0, position <= 50 else {
            return nil
        }

        // Extract series name (optional — nil for position-only patterns)
        var seriesName = ""
        if let nameGroup = nameGroup,
           let nameRange = Range(match.range(at: nameGroup), in: title) {
            seriesName = normalise(String(title[nameRange]))
        }

        return SeriesDetectionResult(
            seriesName: seriesName,
            position: position,
            source: .titlePattern
        )
    }
}
