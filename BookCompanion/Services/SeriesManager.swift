//
//  SeriesManager.swift
//  BookCompanion
//
//  Created for v1.1 series tracking feature.
//
//  Manages series creation, linking, and context building for AI prompts.
//  Injected into ConfirmBookView and SummaryViewModel via BookManager.

import Foundation
import Combine

// MARK: - SeriesContextForAI
// Passed to generate-summary and characters endpoints

struct SeriesContextForAI: Codable {
    let seriesName: String
    let bookPosition: Int
    let totalBooks: Int?
    let completedBooks: [CompletedBook]

    struct CompletedBook: Codable {
        let title: String
        let position: Int
    }
}

// MARK: - SeriesManager

@MainActor
final class SeriesManager: ObservableObject {

    static let shared = SeriesManager()

    @Published private(set) var userSeries: [SeriesRecord] = []

    private init() {}

    // ─────────────────────────────────────────────
    // MARK: - Create or fetch a series
    // Called from ConfirmBookView when user confirms series link.
    // Returns the series UUID to store on the book.
    // ─────────────────────────────────────────────

    func createOrFetchSeries(name: String, totalBooks: Int?) async -> UUID? {
        guard let token = KeychainManager.shared.getUserToken() else { return nil }

        let body: [String: Any] = [
            "name": name,
            "totalBooks": totalBooks as Any
        ]

        do {
            let data = try await post("\(Config.apiEndpoint)/api/series", body: body, token: token)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let seriesDict = json["series"] as? [String: Any],
                  let idString = seriesDict["id"] as? String,
                  let id = UUID(uuidString: idString) else {
                return nil
            }
            return id
        } catch {
            print("❌ SeriesManager.createOrFetchSeries: \(error)")
            return nil
        }
    }

    // ─────────────────────────────────────────────
    // MARK: - AI series detection (sniper call)
    //
    // Called from ConfirmBookView ONLY when both metadata and regex have failed.
    // Fires a minimal Haiku call via the backend — 3s timeout, fails open.
    // Returns nil if: not a series, timed out, network error, or AI is uncertain.
    // Never throws — always returns Optional, never blocks the UI.
    // ─────────────────────────────────────────────

    func detectSeries(title: String, author: String) async -> SeriesDetectionResult? {
        guard let token = KeychainManager.shared.getUserToken() else {
            print("🎯 detectSeries: no token — skipping")
            return nil
        }

        print("🎯 detectSeries: firing for '\(title)' by \(author)")

        let body: [String: Any] = [
            "action": "detect",
            "title":  title,
            "author": author
        ]

        do {
            let data = try await post("\(Config.apiEndpoint)/api/series", body: body, token: token)

            // Log raw response for debugging
            let rawResponse = String(data: data, encoding: .utf8) ?? "nil"
            print("🎯 detectSeries raw response: \(rawResponse)")

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = json["success"] as? Bool, success else {
                print("🎯 detectSeries: success=false or parse failed")
                return nil
            }

            // detected: null is a valid response — book is standalone
            guard let detected = json["detected"] as? [String: Any] else {
                print("🎯 detectSeries: book is standalone (detected: null)")
                return nil
            }

            guard let seriesName = detected["seriesName"] as? String,
                  let position   = detected["position"]   as? Int,
                  !seriesName.isEmpty,
                  position > 0 else {
                print("🎯 detectSeries: invalid shape in detected object: \(detected)")
                return nil
            }

            print("🎯 detectSeries: ✅ found '\(seriesName)' #\(position)")

            return SeriesDetectionResult(
                seriesName: seriesName,
                position:   position,
                source:     .googleBooksMetadata
            )

        } catch {
            // Network error, timeout, or 4xx/5xx — always fail open
            print("⚠️ detectSeries failed silently: \(error.localizedDescription)")
            return nil
        }
    }

    // ─────────────────────────────────────────────
    // MARK: - Link a book to a series
    // Called after book is added to library.
    // ─────────────────────────────────────────────

    func linkBook(bookId: UUID, seriesId: UUID, position: Int) async {
        guard let token = KeychainManager.shared.getUserToken() else { return }

        let body: [String: Any] = [
            "bookId": bookId.uuidString,
            "seriesId": seriesId.uuidString,
            "seriesPosition": position
        ]

        do {
            _ = try await put("\(Config.apiEndpoint)/api/series", body: body, token: token)
            print("✅ SeriesManager: linked book \(bookId) to series \(seriesId) at position \(position)")
        } catch {
            print("❌ SeriesManager.linkBook: \(error)")
        }
    }

    // ─────────────────────────────────────────────
    // MARK: - Unlink a book from its series
    // Called from book detail edit screen.
    // ─────────────────────────────────────────────

    func unlinkBook(bookId: UUID) async {
        guard let token = KeychainManager.shared.getUserToken() else { return }

        let body: [String: Any] = ["bookId": bookId.uuidString]

        do {
            _ = try await delete("\(Config.apiEndpoint)/api/series", body: body, token: token)
            print("✅ SeriesManager: unlinked book \(bookId)")
        } catch {
            print("❌ SeriesManager.unlinkBook: \(error)")
        }
    }

    // ─────────────────────────────────────────────
    // MARK: - Build AI context for a book
    //
    // Given a book that is part of a series, build the SeriesContextForAI
    // struct that gets sent to generate-summary and characters endpoints.
    //
    // Returns nil if the book is standalone or has no prior completed books.
    // ─────────────────────────────────────────────

    func buildAIContext(for book: Book, allBooks: [Book]) -> SeriesContextForAI? {
        guard let seriesId = book.seriesId,
              let position = book.seriesPosition,
              let seriesName = book.seriesName else {
            return nil
        }

        // Find all other books in the same series that the user has completed
        // "Completed" = reading progress chapter >= totalChapters
        let completedPriorBooks = allBooks
            .filter { other in
                other.seriesId == seriesId &&
                other.id != book.id &&
                (other.seriesPosition ?? Int.max) < position &&
                other.isCompleted
            }
            .sorted { ($0.seriesPosition ?? 0) < ($1.seriesPosition ?? 0) }
            .map { SeriesContextForAI.CompletedBook(title: $0.title, position: $0.seriesPosition ?? 0) }

        // Only inject context if at least one prior book is completed
        // No point injecting series block if the user is on book 1
        guard position > 1 || !completedPriorBooks.isEmpty else {
            return nil
        }

        // Find total books in series from any book in the series
        let totalBooks = allBooks
            .first { $0.seriesId == seriesId }
            .flatMap { _ in Optional<Int>.none } // totalBooks comes from series table, not book

        return SeriesContextForAI(
            seriesName: seriesName,
            bookPosition: position,
            totalBooks: totalBooks,
            completedBooks: completedPriorBooks
        )
    }

    // ─────────────────────────────────────────────
    // MARK: - Network helpers
    // ─────────────────────────────────────────────

    private func post(_ urlString: String, body: [String: Any], token: String) async throws -> Data {
        try await request(urlString, method: "POST", body: body, token: token)
    }

    private func put(_ urlString: String, body: [String: Any], token: String) async throws -> Data {
        try await request(urlString, method: "PUT", body: body, token: token)
    }

    private func delete(_ urlString: String, body: [String: Any], token: String) async throws -> Data {
        try await request(urlString, method: "DELETE", body: body, token: token)
    }

    private func request(_ urlString: String, method: String, body: [String: Any], token: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw SeriesError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw SeriesError.requestFailed
        }

        return data
    }
}

// MARK: - SeriesRecord (mirrors series table row)

struct SeriesRecord: Identifiable, Codable {
    let id: UUID
    let name: String
    let totalBooks: Int?
}

// MARK: - Errors

enum SeriesError: LocalizedError {
    case invalidURL
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:     return "Invalid series endpoint URL"
        case .requestFailed:  return "Series request failed"
        }
    }
}
