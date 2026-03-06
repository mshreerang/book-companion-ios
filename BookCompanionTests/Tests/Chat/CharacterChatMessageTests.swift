// CharacterChatMessageTests.swift
// BookCompanionTests
//
// Area 4 — Character Chat: Model correctness, Codable contract, factory methods.

import XCTest
@testable import BookCompanion

final class CharacterChatMessageTests: XCTestCase {

    // MARK: - TC-CH-010 Factory: userMessage role and content

    func test_userMessageFactory_setsRoleAndContent() {
        let msg = CharacterChatMessage.userMessage("What happened at the party?")
        XCTAssertEqual(msg.role, .user)
        XCTAssertEqual(msg.content, "What happened at the party?")
        XCTAssertFalse(msg.isStreaming)
        XCTAssertNil(msg.systemKind)
    }

    // MARK: - TC-CH-011 Factory: characterPlaceholder starts as streaming

    func test_characterPlaceholderFactory_isStreamingAndEmpty() {
        let msg = CharacterChatMessage.characterPlaceholder()
        XCTAssertEqual(msg.role, .character)
        XCTAssertTrue(msg.isStreaming)
        XCTAssertTrue(msg.content.isEmpty)
    }

    // MARK: - TC-CH-012 Factory: safetyBlock has correct systemKind

    func test_safetyBlockFactory_setsSystemKind() {
        let msg = CharacterChatMessage.safetyBlock("I can't discuss that.")
        XCTAssertEqual(msg.role, .system)
        XCTAssertEqual(msg.systemKind, .safetyBlock)
        XCTAssertFalse(msg.isStreaming)
    }

    // MARK: - TC-CH-013 Factory: safetyEnd has correct systemKind

    func test_safetyEndFactory_setsSystemKind() {
        let msg = CharacterChatMessage.safetyEnd("This conversation has ended.")
        XCTAssertEqual(msg.role, .system)
        XCTAssertEqual(msg.systemKind, .safetyEnd)
    }

    // MARK: - TC-CH-014 Factory: quotaLimit has correct systemKind

    func test_quotaLimitFactory_setsSystemKind() {
        let msg = CharacterChatMessage.quotaLimit("Upgrade to Pro.")
        XCTAssertEqual(msg.role, .system)
        XCTAssertEqual(msg.systemKind, .quotaLimit)
    }

    // MARK: - TC-CH-015 Codable: isStreaming is excluded from encoding

    func test_encode_doesNotIncludeIsStreaming() throws {
        var msg = CharacterChatMessage(role: .character, content: "Hello", isStreaming: true)
        let data = try JSONEncoder().encode(msg)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNil(json?["isStreaming"], "isStreaming must be excluded from Codable")
    }

    // MARK: - TC-CH-016 Codable: decode always sets isStreaming to false

    func test_decode_alwaysSetsIsStreamingFalse() throws {
        let msg = CharacterChatMessage(role: .character, content: "Indeed.", isStreaming: true)
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(CharacterChatMessage.self, from: data)
        XCTAssertFalse(decoded.isStreaming, "Decoded message must never be mid-stream")
    }

    // MARK: - TC-CH-017 Codable: systemKind round-trips correctly

    func test_systemKind_roundTrips() throws {
        let msg = CharacterChatMessage.safetyEnd("Session ended.")
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(CharacterChatMessage.self, from: data)
        XCTAssertEqual(decoded.systemKind, .safetyEnd)
        XCTAssertEqual(decoded.role, .system)
    }

    // MARK: - TC-CH-018 Codable: nil systemKind round-trips correctly

    func test_nilSystemKind_roundTrips() throws {
        let msg = CharacterChatMessage.userMessage("Hi")
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(CharacterChatMessage.self, from: data)
        XCTAssertNil(decoded.systemKind)
    }
}
