//
//  ChatSessionStore.swift
//  BookCompanion
//
//  Created by Shree on 27/02/2026.
//

import Foundation

// MARK: - ChatSession (persisted envelope)

struct ChatSession: Codable {
    let messages: [CharacterChatMessage]
    let savedAt: Date
}

// MARK: - ChatSessionStore

/// Caseless enum used as a namespace — no instances, just static methods.
/// Mirrors the project's existing utility pattern.
///
/// Storage key format:
///   "chat:{bookId.uuidString}:{characterName lowercased, spaces→underscores}"
///
/// A session older than 24 hours is treated as expired and returns nil,
/// matching the PRD requirement for session restore.
enum ChatSessionStore {

    // MARK: - Key Generation

    static func key(bookId: UUID, characterName: String) -> String {
        let safeName = characterName
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
        return "chat:\(bookId.uuidString):\(safeName)"
    }

    // MARK: - Save

    /// Persists the current message array.
    /// System messages (safety blocks, quota cards) are excluded —
    /// they are ephemeral UI state and should not reappear on restore.
    static func save(messages: [CharacterChatMessage], key: String) {
        let persistable = messages.filter { $0.role != .system }
        let session = ChatSession(messages: persistable, savedAt: Date())

        guard let data = try? JSONEncoder().encode(session) else {
            print("⚠️ ChatSessionStore: failed to encode session for key \(key)")
            return
        }

        UserDefaults.standard.set(data, forKey: key)
    }

    // MARK: - Load

    /// Returns a stored session if it exists and is less than 24 hours old.
    /// Returns nil if absent, corrupt, or expired — the ViewModel then
    /// starts a fresh greeting.
    static func load(key: String) -> ChatSession? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let session = try? JSONDecoder().decode(ChatSession.self, from: data)
        else {
            return nil
        }

        let age = Date().timeIntervalSince(session.savedAt)
        guard age < 86_400 else {   // 24 hours in seconds
            clearSession(key: key)  // clean up expired session proactively
            return nil
        }

        return session
    }

    // MARK: - Clear

    /// Removes a session from UserDefaults.
    /// Called on:
    ///  - Report submission (user should not re-see reported content)
    ///  - safety_end event (session permanently ended)
    ///  - Explicit "Start Over" action (future)
    static func clearSession(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - Clear All (sign-out / debug)

    /// Removes every chat session key from UserDefaults.
    /// Called from AuthManager.signOut() to avoid stale sessions
    /// appearing after a different user signs in on the same device.
    static func clearAll() {
        let defaults = UserDefaults.standard
        let chatKeys = defaults.dictionaryRepresentation().keys.filter {
            $0.hasPrefix("chat:")
        }
        chatKeys.forEach { defaults.removeObject(forKey: $0) }
        print("✅ ChatSessionStore: cleared \(chatKeys.count) session(s)")
    }
}
