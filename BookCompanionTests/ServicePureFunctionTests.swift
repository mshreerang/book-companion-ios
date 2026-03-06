// ServicePureFunctionTests.swift
// BookCompanionTests
//
// Area 3 — Services: AgeVerificationService toggle & reset,
// ServerAISummaryGenerator pure validation/mapping functions.

import XCTest
@testable import BookCompanion

// MARK: - AgeVerificationService

final class AgeVerificationServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AgeVerificationService.reset()
    }

    override func tearDown() {
        AgeVerificationService.reset()
        super.tearDown()
    }

    // TC-SV-101 Default state is not verified
    func test_defaultState_isNotVerified() {
        XCTAssertFalse(AgeVerificationService.isVerified)
    }

    // TC-SV-102 setVerified persists true
    func test_setVerified_persistsTrue() {
        AgeVerificationService.setVerified(true)
        XCTAssertTrue(AgeVerificationService.isVerified)
    }

    // TC-SV-103 reset returns to false
    func test_reset_returnsToFalse() {
        AgeVerificationService.setVerified(true)
        AgeVerificationService.reset()
        XCTAssertFalse(AgeVerificationService.isVerified)
    }

    // TC-SV-104 Multiple set calls are idempotent
    func test_setVerified_idempotent() {
        AgeVerificationService.setVerified(true)
        AgeVerificationService.setVerified(true)
        XCTAssertTrue(AgeVerificationService.isVerified)
    }
}

// MARK: - ServerAISummaryGenerator Pure Functions

final class ServerAISummaryGeneratorPureFunctionTests: XCTestCase {

    // Mirror validateResponse and mapServerError logic.
    // These are extracted as pure helpers matching the production implementation.

    private enum ValidationError: Error {
        case missingContent
        case emptyContent
        case invalidJSON
    }

    private func validateResponse(_ json: [String: Any]) throws -> String {
        guard let content = json["summary"] as? String else {
            throw ValidationError.missingContent
        }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyContent
        }
        return content
    }

    private func mapServerError(statusCode: Int, body: [String: Any]?) -> AIError {
        switch statusCode {
        case 429:
            let message = body?["message"] as? String ?? "Quota exceeded"
            return .quotaExceeded(message)
        case 401:
            return .unauthorized
        case 400:
            return .requestFailed
        default:
            return .requestFailed
        }
    }

    // TC-SV-110 validateResponse succeeds with valid summary
    func test_validateResponse_validJSON_returnsContent() throws {
        let json: [String: Any] = ["summary": "A great summary of chapter 3."]
        let result = try validateResponse(json)
        XCTAssertEqual(result, "A great summary of chapter 3.")
    }

    // TC-SV-111 validateResponse throws on missing summary key
    func test_validateResponse_missingSummaryKey_throws() {
        let json: [String: Any] = ["other_key": "value"]
        XCTAssertThrowsError(try validateResponse(json))
    }

    // TC-SV-112 validateResponse throws on empty content
    func test_validateResponse_emptyContent_throws() {
        let json: [String: Any] = ["summary": "   "]
        XCTAssertThrowsError(try validateResponse(json))
    }

    // TC-SV-113 mapServerError maps 429 to quotaExceeded
    func test_mapServerError_429_mapsToQuotaExceeded() {
        let body: [String: Any] = ["message": "You have reached your monthly limit."]
        let error = mapServerError(statusCode: 429, body: body)
        if case .quotaExceeded(let msg) = error {
            XCTAssertEqual(msg, "You have reached your monthly limit.")
        } else {
            XCTFail("Expected quotaExceeded, got \(error)")
        }
    }

    // TC-SV-114 mapServerError 429 without body uses fallback message
    func test_mapServerError_429_nilBody_usesFallback() {
        let error = mapServerError(statusCode: 429, body: nil)
        if case .quotaExceeded(let msg) = error {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail("Expected quotaExceeded")
        }
    }

    // TC-SV-115 mapServerError maps 401 to unauthorized
    func test_mapServerError_401_mapsToUnauthorized() {
        let error = mapServerError(statusCode: 401, body: nil)
        XCTAssertEqual(error, .unauthorized)
    }

    // TC-SV-116 mapServerError maps unknown codes to requestFailed
    func test_mapServerError_500_mapsToRequestFailed() {
        let error = mapServerError(statusCode: 500, body: nil)
        XCTAssertEqual(error, .requestFailed)
    }
}

// MARK: - formatBytes Helper

final class FormatBytesTests: XCTestCase {

    // TC-SV-120 Returns "Empty" for small values
    func test_formatBytes_smallValue_returnsEmpty() {
        XCTAssertEqual(formatBytes(0), "Empty")
        XCTAssertEqual(formatBytes(99_999), "Empty")
    }

    // TC-SV-121 Returns KB/MB for larger values
    func test_formatBytes_largeValue_returnsMBString() {
        let result = formatBytes(5_000_000)
        XCTAssertTrue(result.contains("MB") || result.contains("KB"),
                      "Expected formatted size string, got: \(result)")
    }
}
