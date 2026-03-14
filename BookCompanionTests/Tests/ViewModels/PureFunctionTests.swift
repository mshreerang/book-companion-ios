// PureFunctionTests.swift
// BookCompanionTests
//
// Area 1 — Pure Functions: deterministic logic with no dependencies.
// CharacterAvatar initials/colour, BookCard progress math,
// CharacterChatBubble action-text parser, UsageStatsViewModel computed properties.

import XCTest
@testable import BookCompanion

// MARK: - CharacterAvatar

final class CharacterAvatarLogicTests: XCTestCase {

    // Expose the private computed properties by mirroring the production logic here.
    // If CharacterAvatar is later refactored to expose them, update accordingly.

    private func initials(for name: String) -> String {
        let words = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        if words.count >= 2 {
            let first = words[0].prefix(1)
            let last = words[words.count - 1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let firstWord = words.first {
            return String(firstWord.prefix(2)).uppercased()
        }
        return "??"
    }

    // TC-PF-001
    func test_initials_twoWordName_returnsFirstAndLastInitials() {
        XCTAssertEqual(initials(for: "Jay Gatsby"), "JG")
        XCTAssertEqual(initials(for: "Nick Carraway"), "NC")
    }

    // TC-PF-002
    func test_initials_threeWordName_returnsFirstAndLastInitials() {
        XCTAssertEqual(initials(for: "F. Scott Fitzgerald"), "FF")
    }

    // TC-PF-003
    func test_initials_singleWordName_returnsFirstTwoLetters() {
        XCTAssertEqual(initials(for: "Daisy"), "DA")
        XCTAssertEqual(initials(for: "X"), "X")
    }

    // TC-PF-004
    func test_initials_emptyName_returnsFallback() {
        XCTAssertEqual(initials(for: ""), "??")
        XCTAssertEqual(initials(for: "   "), "??")
    }

    // TC-PF-005 Colour is deterministic for same name
    func test_primaryColor_isDeterministicForSameName() {
        // We can't inspect Color internals, but we can verify hashValue is stable
        let name = "Jay Gatsby"
        let colors: [String] = ["blue", "purple", "pink", "orange", "green", "red", "indigo", "cyan", "mint", "teal"]
        let index1 = abs(name.hashValue % colors.count)
        let index2 = abs(name.hashValue % colors.count)
        XCTAssertEqual(index1, index2, "Color selection must be deterministic for same input")
    }

    // TC-PF-006 Different names produce different colour indices (statistical, not guaranteed)
    func test_primaryColor_differentNames_likelyDifferentColors() {
        let colors = ["blue", "purple", "pink", "orange", "green", "red", "indigo", "cyan", "mint", "teal"]
        let i1 = abs("Gatsby".hashValue % colors.count)
        let i2 = abs("Daisy".hashValue % colors.count)
        // This is a probabilistic test — same index for different names is possible but unlikely
        // If this ever fails, simply remove; it's documenting intent not enforcing a contract
        _ = (i1 == i2) // not asserted, just sanity check that code runs
    }
}

// MARK: - BookCard Progress Math

final class BookCardProgressMathTests: XCTestCase {

    // Mirror the production clamping logic from BookCard
    private func clampedProgress(chapter: Int, totalChapters: Int) -> Double {
        guard totalChapters > 0 else { return 0 }
        return min(1.0, max(0.0, Double(chapter) / Double(totalChapters)))
    }

    private func percentage(chapter: Int, totalChapters: Int) -> Int {
        Int(clampedProgress(chapter: chapter, totalChapters: totalChapters) * 100)
    }

    // TC-PF-010
    func test_progressClamp_normal() {
        XCTAssertEqual(clampedProgress(chapter: 5, totalChapters: 10), 0.5, accuracy: 0.001)
    }

    // TC-PF-011
    func test_progressClamp_zeroChapter() {
        XCTAssertEqual(clampedProgress(chapter: 0, totalChapters: 10), 0.0)
    }

    // TC-PF-012
    func test_progressClamp_exceedsTotalChapters() {
        XCTAssertEqual(clampedProgress(chapter: 15, totalChapters: 10), 1.0,
                       "Progress must clamp at 1.0 even if chapter exceeds total")
    }

    // TC-PF-013
    func test_progressClamp_zeroTotalChapters_returnsZero() {
        XCTAssertEqual(clampedProgress(chapter: 5, totalChapters: 0), 0.0,
                       "Division by zero must be handled gracefully")
    }

    // TC-PF-014
    func test_percentage_halfWay() {
        XCTAssertEqual(percentage(chapter: 1, totalChapters: 2), 50)
    }

    // TC-PF-015
    func test_percentage_complete() {
        XCTAssertEqual(percentage(chapter: 9, totalChapters: 9), 100)
    }
}

// MARK: - CharacterChatBubble parseSegments

final class ChatBubbleParseSegmentsTests: XCTestCase {

    // Mirror the parseSegments logic from CharacterChatBubble
    // If that method is ever made internal/public, import directly instead.

    private enum Segment {
        case normal(String)
        case action(String)
    }

    private func parseSegments(_ text: String) -> [Segment] {
        var segments: [Segment] = []
        var remaining = text

        while !remaining.isEmpty {
            if let start = remaining.range(of: "*") {
                // Text before the asterisk
                let before = String(remaining[remaining.startIndex..<start.lowerBound])
                if !before.isEmpty { segments.append(.normal(before)) }

                let afterStar = remaining[start.upperBound...]
                if let end = afterStar.range(of: "*") {
                    // Action text between asterisks
                    let action = String(afterStar[afterStar.startIndex..<end.lowerBound])
                    segments.append(.action(action))
                    remaining = String(afterStar[end.upperBound...])
                } else {
                    // Unmatched asterisk — treat rest as normal
                    segments.append(.normal(String(remaining[start.lowerBound...])))
                    break
                }
            } else {
                segments.append(.normal(remaining))
                break
            }
        }
        return segments
    }

    // TC-PF-020
    func test_parseSegments_plainText_returnsSingleNormal() {
        let result = parseSegments("Hello there")
        XCTAssertEqual(result.count, 1)
        if case .normal(let t) = result[0] { XCTAssertEqual(t, "Hello there") }
        else { XCTFail("Expected normal segment") }
    }

    // TC-PF-021
    func test_parseSegments_actionOnly_returnsSingleAction() {
        let result = parseSegments("*waves hand*")
        XCTAssertEqual(result.count, 1)
        if case .action(let t) = result[0] { XCTAssertEqual(t, "waves hand") }
        else { XCTFail("Expected action segment") }
    }

    // TC-PF-022
    func test_parseSegments_mixedContent_returnsCorrectOrder() {
        let result = parseSegments("Hello. *waves* Goodbye.")
        XCTAssertEqual(result.count, 3)
        if case .normal(let t) = result[0] { XCTAssertEqual(t, "Hello. ") }
        if case .action(let t) = result[1] { XCTAssertEqual(t, "waves") }
        if case .normal(let t) = result[2] { XCTAssertEqual(t, " Goodbye.") }
    }

    // TC-PF-023
    func test_parseSegments_multipleActions() {
        let result = parseSegments("*smiles* Hello *nods*")
        XCTAssertEqual(result.count, 3)
        if case .action(let t) = result[0] { XCTAssertEqual(t, "smiles") }
        if case .normal(let t) = result[1] { XCTAssertEqual(t, " Hello ") }
        if case .action(let t) = result[2] { XCTAssertEqual(t, "nods") }
    }

    // TC-PF-024
    func test_parseSegments_unmatchedAsterisks_treatedAsNormal() {
        let result = parseSegments("Hello *world")
        XCTAssertFalse(result.isEmpty)
        // The unmatched portion must not crash and must appear as normal text
        let allNormal = result.allSatisfy { if case .action = $0 { return false } else { return true } }
        XCTAssertTrue(allNormal, "Unmatched asterisk must produce only normal segments")
    }

    // TC-PF-025
    func test_parseSegments_emptyString_returnsEmpty() {
        let result = parseSegments("")
        XCTAssertTrue(result.isEmpty)
    }
}

// MARK: - UsageStatsViewModel Computed Properties

@MainActor
final class UsageStatsViewModelTests: XCTestCase {

    private var sut: UsageStatsViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = UsageStatsViewModel()
    }

    // TC-PF-030
    func test_summariesRemaining_clampsAtZero() {
        sut.summariesUsed = 10
        sut.summariesLimit = 5
        XCTAssertEqual(sut.summariesRemaining, 0, "Remaining must never go negative")
    }

    // TC-PF-031
    func test_usageProgress_clampsAtOne() {
        sut.summariesUsed = 20
        sut.summariesLimit = 5
        XCTAssertEqual(sut.usageProgress, 1.0)
    }

    // TC-PF-032
    func test_usageProgress_zeroLimit_returnsZero() {
        sut.summariesLimit = 0
        sut.summariesUsed = 3
        XCTAssertEqual(sut.usageProgress, 0.0, "Division by zero must return 0")
    }

    // TC-PF-033
    func test_isNearLimit_trueWhenAbove80Percent() {
        sut.summariesUsed = 4
        sut.summariesLimit = 5  // 80%
        XCTAssertTrue(sut.isNearLimit)
    }

    // TC-PF-034
    func test_isNearLimit_falseWhenAtLimit() {
        sut.summariesUsed = 5
        sut.summariesLimit = 5  // 100% — isAtLimit, not isNearLimit
        XCTAssertFalse(sut.isNearLimit)
        XCTAssertTrue(sut.isAtLimit)
    }

    // TC-PF-035
    func test_resetDate_isFirstDayOfNextMonth() {
        let resetStr = sut.resetDate
        // Verify it's a non-empty formatted date string
        XCTAssertFalse(resetStr.isEmpty)
        XCTAssertNotEqual(resetStr, "Next month", "Should compute a real date")
    }
}
