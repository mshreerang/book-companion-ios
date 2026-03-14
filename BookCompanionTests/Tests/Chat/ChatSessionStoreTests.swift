// ChatSessionStoreTests.swift
// BookCompanionTests
//
// Area 4 — Character Chat: Session persistence, 24h expiry, system message filtering.

import XCTest
@testable import BookCompanion

final class ChatSessionStoreTests: XCTestCase {

    private let bookId = UUID(uuidString: "C3D4E5F6-0000-0000-0000-000000000003")!
    private let characterName = "Jay Gatsby"
    private var sessionKey: String!

    override func setUp() async throws {
        try await super.setUp()
        sessionKey = await MainActor.run {
            ChatSessionStore.key(bookId: bookId, characterName: characterName)
        }
        await MainActor.run { ChatSessionStore.clearSession(key: sessionKey) }
    }

    override func tearDown() async throws {
        await MainActor.run { ChatSessionStore.clearSession(key: sessionKey) }
        try await super.tearDown()
    }

    // MARK: - TC-CH-001 Key generation is deterministic and has correct prefix

    func test_keyGeneration_isDeterministicAndSafe() async {
        await MainActor.run {
            let key1 = ChatSessionStore.key(bookId: bookId, characterName: "Jay Gatsby")
            let key2 = ChatSessionStore.key(bookId: bookId, characterName: "Jay Gatsby")
            XCTAssertEqual(key1, key2)
            XCTAssertTrue(key1.hasPrefix("chat:"))
            XCTAssertFalse(key1.contains(" "), "Key must not contain spaces")
        }
    }

    // MARK: - TC-CH-002 Save and load round-trip returns messages

    func test_saveAndLoad_returnsStoredMessages() async {
        await MainActor.run {
            let messages: [CharacterChatMessage] = [
                .userMessage("Hello Gatsby"),
                CharacterChatMessage(role: .character, content: "Old sport!")
            ]
            ChatSessionStore.save(messages: messages, key: sessionKey)
            let loaded = ChatSessionStore.load(key: sessionKey)
            XCTAssertNotNil(loaded)
            XCTAssertEqual(loaded?.messages.count, 2)
            XCTAssertEqual(loaded?.messages[0].content, "Hello Gatsby")
        }
    }

    // MARK: - TC-CH-003 System messages are stripped on save

    func test_save_stripsSystemMessages() async {
        await MainActor.run {
            let messages: [CharacterChatMessage] = [
                .userMessage("Hello"),
                CharacterChatMessage(role: .character, content: "Indeed."),
                .safetyBlock("This topic is off-limits."),
                .quotaLimit("You've reached your limit.")
            ]
            ChatSessionStore.save(messages: messages, key: sessionKey)
            let loaded = ChatSessionStore.load(key: sessionKey)
            XCTAssertNotNil(loaded)
            XCTAssertEqual(loaded?.messages.count, 2, "System messages must not be persisted")
            XCTAssertTrue(loaded?.messages.allSatisfy { $0.role != .system } ?? false)
        }
    }

    // MARK: - TC-CH-004 isStreaming is always false after decode

    func test_load_alwaysSetsIsStreamingToFalse() async {
        await MainActor.run {
            let msg = CharacterChatMessage.characterPlaceholder()
            XCTAssertTrue(msg.isStreaming, "Placeholder must start as streaming")
            ChatSessionStore.save(messages: [msg], key: sessionKey)
            let loaded = ChatSessionStore.load(key: sessionKey)
            XCTAssertFalse(loaded?.messages.first?.isStreaming ?? true,
                           "isStreaming must be false after decode")
        }
    }

    // MARK: - TC-CH-005 Session expired after 24 hours returns nil

    func test_load_expiredSession_returnsNil() async throws {
        try await MainActor.run {
            let messages: [CharacterChatMessage] = [.userMessage("Old message")]
            let expiredSession = ChatSession(
                messages: messages,
                savedAt: Date().addingTimeInterval(-25 * 3600)
            )
            let data = try JSONEncoder().encode(expiredSession)
            UserDefaults.standard.set(data, forKey: sessionKey)
            let loaded = ChatSessionStore.load(key: sessionKey)
            XCTAssertNil(loaded, "Sessions older than 24h must return nil")
            XCTAssertNil(UserDefaults.standard.data(forKey: sessionKey),
                         "Expired session must be removed from UserDefaults")
        }
    }

    // MARK: - TC-CH-006 clearSession removes the key

    func test_clearSession_removesStoredData() async {
        await MainActor.run {
            ChatSessionStore.save(messages: [.userMessage("Hi")], key: sessionKey)
            XCTAssertNotNil(ChatSessionStore.load(key: sessionKey))
            ChatSessionStore.clearSession(key: sessionKey)
            XCTAssertNil(ChatSessionStore.load(key: sessionKey))
        }
    }

    // MARK: - TC-CH-007 clearAll removes all chat: keys

    func test_clearAll_removesAllChatKeys() async {
        await MainActor.run {
            let key1 = ChatSessionStore.key(bookId: bookId, characterName: "Gatsby")
            let key2 = ChatSessionStore.key(bookId: bookId, characterName: "Daisy")
            ChatSessionStore.save(messages: [.userMessage("Hi")], key: key1)
            ChatSessionStore.save(messages: [.userMessage("Hello")], key: key2)
            ChatSessionStore.clearAll()
            XCTAssertNil(ChatSessionStore.load(key: key1))
            XCTAssertNil(ChatSessionStore.load(key: key2))
        }
    }

    // MARK: - TC-CH-008 Load returns nil for missing key

    func test_load_missingKey_returnsNil() async {
        await MainActor.run {
            let result = ChatSessionStore.load(key: "chat:nonexistent:key")
            XCTAssertNil(result)
        }
    }
}
