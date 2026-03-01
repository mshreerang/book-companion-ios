//
//  CharacterChatMessage.swift
//  BookCompanion
//
//  Created by Shree on 27/02/2026.
//

import Foundation

// MARK: - Message Role

enum MessageRole: String, Codable {
    case user
    case character
    case system      // quota limit cards, safety block cards — never sent to API
}

// MARK: - System Message Kind
// Drives bubble rendering without requiring the View to inspect content strings

enum SystemMessageKind: String, Codable {
    case safetyBlock       // Tier 1 / Tier 3 — soft red bubble, no CTA
    case safetyEnd         // Tier 2 triggered — session permanently locked
    case quotaLimit        // Free tier gate — amber bubble, upgrade CTA
}

// MARK: - CharacterChatMessage

struct CharacterChatMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    var content: String
    let timestamp: Date

    // Only set when role == .system
    var systemKind: SystemMessageKind?

    // True only on the single in-flight character message while streaming.
    // Stored as var so the ViewModel can flip it to false on "done" / "safety_replaced".
    // Never persisted to disk (ChatSessionStore strips isStreaming before saving).
    var isStreaming: Bool

    // MARK: - Initialisers

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        systemKind: SystemMessageKind? = nil,
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.systemKind = systemKind
        self.isStreaming = isStreaming
    }

    // MARK: - Codable
    // Exclude isStreaming from persistence — a message is never mid-stream on restore.

    enum CodingKeys: String, CodingKey {
        case id, role, content, timestamp, systemKind
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id         = try c.decode(UUID.self,              forKey: .id)
        role       = try c.decode(MessageRole.self,       forKey: .role)
        content    = try c.decode(String.self,            forKey: .content)
        timestamp  = try c.decode(Date.self,              forKey: .timestamp)
        systemKind = try c.decodeIfPresent(SystemMessageKind.self, forKey: .systemKind)
        isStreaming = false   // always false on restore
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,         forKey: .id)
        try c.encode(role,       forKey: .role)
        try c.encode(content,    forKey: .content)
        try c.encode(timestamp,  forKey: .timestamp)
        try c.encodeIfPresent(systemKind, forKey: .systemKind)
        // isStreaming intentionally omitted
    }

    // MARK: - Convenience Factories

    static func userMessage(_ text: String) -> CharacterChatMessage {
        CharacterChatMessage(role: .user, content: text)
    }

    static func characterPlaceholder() -> CharacterChatMessage {
        CharacterChatMessage(role: .character, content: "", isStreaming: true)
    }

    static func safetyBlock(_ text: String) -> CharacterChatMessage {
        CharacterChatMessage(role: .system, content: text, systemKind: .safetyBlock)
    }

    static func safetyEnd(_ text: String) -> CharacterChatMessage {
        CharacterChatMessage(role: .system, content: text, systemKind: .safetyEnd)
    }

    static func quotaLimit(_ text: String) -> CharacterChatMessage {
        CharacterChatMessage(role: .system, content: text, systemKind: .quotaLimit)
    }
}
