// AccessibilityTests.swift
// BookCompanionTests
//
// Area 13 — Accessibility: Verify A11y identifier constants are non-empty
// and unique. These tests guard against accidental regressions where a
// refactor wipes or duplicates VoiceOver labels.

import XCTest
@testable import BookCompanion

final class AccessibilityIdentifierTests: XCTestCase {

    // TC-A11Y-001 All A11y.Library identifiers are non-empty strings
    func test_libraryIdentifiers_areNonEmpty() {
        XCTAssertFalse(A11y.Library.searchButton.isEmpty)
        XCTAssertFalse(A11y.Library.settingsButton.isEmpty)
        XCTAssertFalse(A11y.Library.settingsButtonHint.isEmpty)
    }

    // TC-A11Y-002 A11y.Library identifiers are unique
    func test_libraryIdentifiers_areUnique() {
        let ids = [
            A11y.Library.searchButton,
            A11y.Library.settingsButton
        ]
        XCTAssertEqual(Set(ids).count, ids.count, "Accessibility identifiers must be unique within their namespace")
    }

    // TC-A11Y-003 All A11y namespaces have non-empty identifiers
    // Expand this test as new A11y namespaces are added
    func test_allKnownA11yConstants_areNonEmpty() {
        // Add all A11y constants here as the enum grows.
        // This test will fail (and remind you to add entries) when new
        // constants are introduced with empty strings.
        let allConstants: [String] = [
            A11y.Library.searchButton,
            A11y.Library.settingsButton,
            A11y.Library.settingsButtonHint,
            // Add: A11y.Summary.*, A11y.Characters.*, A11y.Chat.*
            // as they are added to AccessibilityIdentifiers.swift
        ]

        for constant in allConstants {
            XCTAssertFalse(constant.isEmpty, "A11y constant must not be empty: found empty string")
        }
    }

    // TC-A11Y-004 A11y hint strings are descriptive (length > 5 chars)
    func test_hintStrings_areDescriptive() {
        let hints = [
            A11y.Library.settingsButtonHint
        ]
        for hint in hints {
            XCTAssertGreaterThan(hint.count, 5,
                                 "Hint '\(hint)' is too short to be useful for VoiceOver")
        }
    }
}
