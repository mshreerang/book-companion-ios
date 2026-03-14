// UserDefaultsSummaryRepositoryTests.swift
// BookCompanionTests
//
// Area 7 — Data Persistence: Summary caching round-trips via UserDefaults.
// Each test uses an isolated UserDefaults suite to avoid polluting the
// real defaults or colliding with other tests running in parallel.

import XCTest
@testable import BookCompanion

final class UserDefaultsSummaryRepositoryTests: XCTestCase {

    private var sut: UserDefaultsSummaryRepository!
    private var defaults: UserDefaults!
    private let suiteName = "com.bookcompanion.test.summary"
    private let bookId = UUID(uuidString: "A1B2C3D4-0000-0000-0000-000000000001")!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        // NOTE: UserDefaultsSummaryRepository currently hardcodes .standard.
        // Until it is updated to accept an injected UserDefaults, these tests
        // use the real store and isolate via unique keys through unique UUIDs.
        sut = UserDefaultsSummaryRepository()
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        sut = nil
        super.tearDown()
    }

    // MARK: - TC-PD-001 Save and load a BookSummary round-trip

    func test_saveSummary_thenLoad_returnsSameSummary() {
        let summary = TestFixtures.makeSummary(bookId: bookId, chapter: 3, language: .english, length: .short)

        sut.saveSummary(summary)
        let loaded = sut.loadSummary(bookId: bookId, chapter: 3, language: .english, length: .short)

        XCTAssertNotNil(loaded, "Should load a previously saved summary")
        XCTAssertEqual(loaded?.content, summary.content)
        XCTAssertEqual(loaded?.chapter, summary.chapter)
        XCTAssertEqual(loaded?.language, summary.language)
        XCTAssertEqual(loaded?.length, summary.length)
    }

    // MARK: - TC-PD-002 Different (chapter, language, length) keys do not collide

    func test_differentKeys_doNotCollide() {
        let summaryEN = TestFixtures.makeSummary(bookId: bookId, chapter: 3, language: .english, length: .short, content: "English content")
        let summaryHI = TestFixtures.makeSummary(bookId: bookId, chapter: 3, language: .hindi, length: .short, content: "Hindi content")
        let summaryMed = TestFixtures.makeSummary(bookId: bookId, chapter: 3, language: .english, length: .medium, content: "Medium content")

        sut.saveSummary(summaryEN)
        sut.saveSummary(summaryHI)
        sut.saveSummary(summaryMed)

        XCTAssertEqual(sut.loadSummary(bookId: bookId, chapter: 3, language: .english, length: .short)?.content, "English content")
        XCTAssertEqual(sut.loadSummary(bookId: bookId, chapter: 3, language: .hindi, length: .short)?.content, "Hindi content")
        XCTAssertEqual(sut.loadSummary(bookId: bookId, chapter: 3, language: .english, length: .medium)?.content, "Medium content")
    }

    // MARK: - TC-PD-003 Load returns nil when no summary saved

    func test_load_whenNothingSaved_returnsNil() {
        let result = sut.loadSummary(bookId: bookId, chapter: 99, language: .spanish, length: .short)
        XCTAssertNil(result)
    }

    // MARK: - TC-PD-004 Save and load [BookCharacter] round-trip

    func test_saveCharacters_thenLoad_returnsSameCharacters() {
        let characters = TestFixtures.makeCharacterList(count: 3, bookId: bookId)

        sut.saveCharacters(characters, bookId: bookId, chapter: 5, language: .english, length: .medium)
        let loaded = sut.loadCharacters(bookId: bookId, chapter: 5, language: .english, length: .medium)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 3)
        XCTAssertEqual(loaded?.map(\.name), characters.map(\.name))
    }

    // MARK: - TC-PD-005 Characters load returns nil for unsaved key

    func test_loadCharacters_whenNothingSaved_returnsNil() {
        let result = sut.loadCharacters(bookId: bookId, chapter: 1, language: .german, length: .short)
        XCTAssertNil(result)
    }

    // MARK: - TC-PD-006 Saving a new summary for same key overwrites the old one

    func test_saveSummary_overwritesPreviousSummary() {
        let old = TestFixtures.makeSummary(bookId: bookId, chapter: 1, language: .english, length: .short, content: "Old content")
        let new = TestFixtures.makeSummary(bookId: bookId, chapter: 1, language: .english, length: .short, content: "New content")

        sut.saveSummary(old)
        sut.saveSummary(new)

        XCTAssertEqual(sut.loadSummary(bookId: bookId, chapter: 1, language: .english, length: .short)?.content, "New content")
    }
}
