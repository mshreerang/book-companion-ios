// UserDefaultsProgressRepositoryTests.swift
// BookCompanionTests
//
// Area 7 — Data Persistence: Reading progress save/load via UserDefaults.

import XCTest
@testable import BookCompanion

final class UserDefaultsProgressRepositoryTests: XCTestCase {

    private var sut: UserDefaultsProgressRepository!
    private let bookId = UUID(uuidString: "B2C3D4E5-0000-0000-0000-000000000002")!

    override func setUp() {
        super.setUp()
        sut = UserDefaultsProgressRepository()
        // Clean up the key this test will write
        UserDefaults.standard.removeObject(forKey: "reading_progress_\(bookId.uuidString)")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "reading_progress_\(bookId.uuidString)")
        sut = nil
        super.tearDown()
    }

    // MARK: - TC-PD-007 Save and load ReadingProgress round-trip

    func test_saveProgress_thenLoad_returnsSameProgress() {
        let progress = ReadingProgress(id: UUID(), bookId: bookId, chapter: 7, language: .hindi, updatedAt: Date())

        sut.saveProgress(progress)
        let loaded = sut.loadProgress(for: bookId.uuidString)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.chapter, 7)
        XCTAssertEqual(loaded?.language, .hindi)
        XCTAssertEqual(loaded?.bookId, bookId)
    }

    // MARK: - TC-PD-008 loadProgress returns nil when nothing saved

    func test_loadProgress_whenNothingSaved_returnsNil() {
        let randomId = UUID().uuidString
        XCTAssertNil(sut.loadProgress(for: randomId))
    }

    // MARK: - TC-PD-009 Saving progress overwrites previous value

    func test_saveProgress_overwritesPreviousValue() {
        let first  = ReadingProgress(id: UUID(), bookId: bookId, chapter: 3, language: .english, updatedAt: Date())
        let second = ReadingProgress(id: UUID(), bookId: bookId, chapter: 8, language: .marathi, updatedAt: Date())

        sut.saveProgress(first)
        sut.saveProgress(second)

        let loaded = sut.loadProgress(for: bookId.uuidString)
        XCTAssertEqual(loaded?.chapter, 8)
        XCTAssertEqual(loaded?.language, .marathi)
    }

    // MARK: - TC-PD-010 ProgressRepository protocol uses String, implementation uses UUID — key alignment

    func test_keyAlignment_stringAndUUID() {
        // ProgressRepository.loadProgress takes String.
        // UserDefaultsProgressRepository.saveProgress uses bookId.uuidString.
        // Verifies both sides of the interface agree on the key format.
        let progress = ReadingProgress(id: UUID(), bookId: bookId, chapter: 2, language: .spanish, updatedAt: Date())

        sut.saveProgress(progress)

        // Load using the UUID string — must match
        let loaded = sut.loadProgress(for: bookId.uuidString)
        XCTAssertNotNil(loaded, "Key alignment between save (UUID) and load (String) must be consistent")
    }
}
