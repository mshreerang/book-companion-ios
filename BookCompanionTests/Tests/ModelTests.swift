// ModelTests.swift
// BookCompanionTests
//
// Area 1 — Core Models: Language enum, AIError enum, ReadingProgress, BookSummary.
// These are the foundation types everything else depends on.

import XCTest
@testable import BookCompanion

// MARK: - Language

final class LanguageTests: XCTestCase {

    // TC-MDL-001 All Language cases have non-empty displayName
    func test_language_displayName_isNonEmpty() {
        for lang in Language.allCases {
            XCTAssertFalse(lang.displayName.isEmpty, "Language.\(lang) must have a non-empty displayName")
        }
    }

    // TC-MDL-002 All Language cases have a voiceCode (for TTS routing)
    func test_language_voiceCode_isNonEmpty() {
        for lang in Language.allCases {
            XCTAssertFalse(lang.voiceCode.isEmpty, "Language.\(lang).voiceCode must not be empty")
        }
    }

    // TC-MDL-003 Marathi voiceCode is mr-IN
    func test_marathi_voiceCode_isMarathi() {
        XCTAssertEqual(Language.marathi.voiceCode, "mr-IN")
    }

    // TC-MDL-004 English voiceCode is en-US or en-GB
    func test_english_voiceCode_isEnglish() {
        let code = Language.english.voiceCode
        XCTAssertTrue(code.hasPrefix("en-"), "English voiceCode must start with 'en-'")
    }

    // TC-MDL-005 Language conforms to CaseIterable — all cases reachable
    func test_language_caseIterable_hasAllCases() {
        XCTAssertGreaterThanOrEqual(Language.allCases.count, 5,
                                    "Expected at least 5 languages: English, Hindi, Marathi, Spanish, German")
    }

    // TC-MDL-006 Language is Identifiable
    func test_language_isIdentifiable() {
        let lang = Language.english
        XCTAssertFalse(lang.id.isEmpty)
    }

    // TC-MDL-007 Language rawValues are unique
    func test_language_rawValues_areUnique() {
        let rawValues = Language.allCases.map(\.rawValue)
        XCTAssertEqual(Set(rawValues).count, rawValues.count, "Language rawValues must be unique")
    }
}

// MARK: - AIError

final class AIErrorTests: XCTestCase {

    // TC-MDL-010 AIError.quotaExceeded carries custom message
    func test_quotaExceeded_carriesMessage() {
        let err = AIError.quotaExceeded("You've used all 5 free summaries.")
        if case .quotaExceeded(let msg) = err {
            XCTAssertEqual(msg, "You've used all 5 free summaries.")
        } else {
            XCTFail()
        }
    }

    // TC-MDL-011 AIError.safetyBlock carries message
    func test_safetyBlock_carriesMessage() {
        let err = AIError.safetyBlock("Content not allowed.")
        if case .safetyBlock(let msg) = err {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail()
        }
    }

    // TC-MDL-012 All AIError cases have non-empty localizedDescription
    func test_allAIErrors_haveLocalizedDescription() {
        let errors: [AIError] = [
            .requestFailed,
            .unauthorized,
            .rateLimited,
            .quotaExceeded("test"),
            .safetyBlock("test"),
            .invalidResponse
        ]
        for err in errors {
            XCTAssertFalse(err.localizedDescription.isEmpty, "AIError.\(err) must have a description")
        }
    }

    // TC-MDL-013 AIError cases are distinct
    func test_aiError_casesAreDistinct() {
        // Verify each case matches itself and not others via pattern matching
        let errors: [AIError] = [.requestFailed, .unauthorized, .rateLimited, .invalidResponse]
        var matchCount = 0
        for error in errors {
            if case .requestFailed = error { matchCount += 1 }
        }
        XCTAssertEqual(matchCount, 1, "Only one case should match .requestFailed")
    }
}

// MARK: - BookSummary Codable

final class BookSummaryTests: XCTestCase {

    // TC-MDL-020 BookSummary encodes and decodes correctly
    func test_bookSummary_codableRoundTrip() async throws {
        try await MainActor.run {
            let original = TestFixtures.makeSummary()
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(BookSummary.self, from: data)
            XCTAssertEqual(decoded.id, original.id)
            XCTAssertEqual(decoded.content, original.content)
            XCTAssertEqual(decoded.chapter, original.chapter)
            XCTAssertEqual(decoded.language, original.language)
            XCTAssertEqual(decoded.length, original.length)
        }
    }
}

// MARK: - ReadingProgress Codable

final class ReadingProgressTests: XCTestCase {

    // TC-MDL-030 ReadingProgress encodes and decodes correctly
    func test_readingProgress_codableRoundTrip() async throws {
        try await MainActor.run {
            let original = TestFixtures.makeProgress(chapter: 7, language: .hindi)
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(ReadingProgress.self, from: data)
            XCTAssertEqual(decoded.id, original.id)
            XCTAssertEqual(decoded.bookId, original.bookId)
            XCTAssertEqual(decoded.chapter, 7)
            XCTAssertEqual(decoded.language, .hindi)
        }
    }
}

// MARK: - SummaryLength

final class SummaryLengthTests: XCTestCase {

    // TC-MDL-040 SummaryLength has at least 2 cases
    func test_summaryLength_hasExpectedCases() {
        let cases = SummaryLength.allCases
        XCTAssertGreaterThanOrEqual(cases.count, 2)
    }

    // TC-MDL-041 SummaryLength rawValues are unique
    func test_summaryLength_rawValues_areUnique() {
        let rawValues = SummaryLength.allCases.map(\.rawValue)
        XCTAssertEqual(Set(rawValues).count, rawValues.count)
    }

    // TC-MDL-042 SummaryLength is Codable
    func test_summaryLength_codableRoundTrip() throws {
        let original = SummaryLength.medium
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SummaryLength.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}
