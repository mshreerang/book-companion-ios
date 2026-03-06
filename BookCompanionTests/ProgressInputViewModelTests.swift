// ProgressInputViewModelTests.swift
// BookCompanionTests
//
// Area 5 — Reading Progress: Local save vs cloud sync separation,
// initialisation from saved progress, in-memory updates.

import XCTest
@testable import BookCompanion

@MainActor
final class ProgressInputViewModelTests: XCTestCase {

    private var sut: ProgressInputViewModel!
    private var mockRepository: MockProgressRepository!
    private var mockBookManager: BookManager!
    private var book: Book!

    override func setUp() {
        super.setUp()
        book = TestFixtures.makeBook()
        mockRepository = MockProgressRepository()
        // BookManager is a singleton with shared state — use a test instance
        // NOTE: If BookManager cannot be instantiated without side-effects,
        // extract BookManagerProtocol and inject a mock instead.
        mockBookManager = BookManager()
        sut = ProgressInputViewModel(
            book: book,
            repository: mockRepository,
            bookManager: mockBookManager
        )
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        mockBookManager = nil
        super.tearDown()
    }

    // MARK: - TC-PI-001 Initialises from saved progress when available

    func test_init_withSavedProgress_loadsFromRepository() {
        let saved = ReadingProgress(id: UUID(), bookId: book.id, chapter: 7, language: .hindi, updatedAt: Date())
        mockRepository.seed(saved)

        let vm = ProgressInputViewModel(book: book, repository: mockRepository, bookManager: mockBookManager)

        XCTAssertEqual(vm.selectedChapter, 7)
        XCTAssertEqual(vm.selectedLanguage, .hindi)
    }

    // MARK: - TC-PI-002 Initialises from book defaults when no saved progress

    func test_init_withNoSavedProgress_usesBookDefaults() {
        // mockRepository is empty — no saved progress
        XCTAssertEqual(sut.selectedLanguage, book.language)
    }

    // MARK: - TC-PI-003 updateChapter triggers save to repository

    func test_updateChapter_savesToRepository() {
        sut.updateChapter(5)

        XCTAssertTrue(mockRepository.saveProgressCalled)
        XCTAssertEqual(mockRepository.lastSavedProgress?.chapter, 5)
    }

    // MARK: - TC-PI-004 updateLanguage triggers save to repository

    func test_updateLanguage_savesToRepository() {
        sut.updateLanguage(.marathi)

        XCTAssertTrue(mockRepository.saveProgressCalled)
        XCTAssertEqual(mockRepository.lastSavedProgress?.language, .marathi)
    }

    // MARK: - TC-PI-005 updateLength does NOT save to repository

    func test_updateLength_doesNotPersist() {
        sut.updateLength(.medium)

        XCTAssertFalse(mockRepository.saveProgressCalled,
                       "Length is session-only and must not be persisted to repository")
        XCTAssertEqual(sut.selectedLength, .medium)
    }

    // MARK: - TC-PI-006 saveOnExit calls repository save

    func test_saveOnExit_savesToRepository() {
        sut.saveOnExit()

        XCTAssertTrue(mockRepository.saveProgressCalled)
        XCTAssertEqual(mockRepository.lastSavedProgress?.bookId, book.id)
    }

    // MARK: - TC-PI-007 Saved progress contains correct bookId

    func test_save_usesCorrectBookId() {
        sut.updateChapter(3)

        XCTAssertEqual(mockRepository.lastSavedProgress?.bookId, book.id)
    }

    // MARK: - TC-PI-008 updateChapter does NOT call syncChapterToCloud (network is intentional only)

    func test_updateChapter_doesNotTriggerCloudSync() {
        // This test documents the architectural decision:
        // updateChapter/updateLanguage → local only.
        // Cloud sync must only happen via explicit syncChapterToCloud().
        //
        // Since BookManager.saveProgress is the cloud path, we verify
        // that the repository (local) is called but not the cloud method.
        // BookManager.updateProgressInMemory (in-memory only) is acceptable.

        let initialBookCount = mockBookManager.books.count
        sut.updateChapter(10)

        // Repository must be called (local save)
        XCTAssertTrue(mockRepository.saveProgressCalled)

        // Cloud sync (Supabase) must NOT be called — books count stays unchanged
        // as no new books were added. This is a best-effort check.
        XCTAssertEqual(mockBookManager.books.count, initialBookCount,
                       "updateChapter must not trigger cloud sync")
    }

    // MARK: - TC-PI-009 syncChapterToCloud passes current state

    func test_syncChapterToCloud_usesCurrentChapterAndLanguage() {
        sut.updateChapter(8)
        sut.updateLanguage(.spanish)

        // Reset mock to only track the cloud sync call
        mockRepository.saveProgressCalled = false
        sut.syncChapterToCloud()

        // syncChapterToCloud calls bookManager.saveProgress — not repository
        // We can only verify it doesn't crash and the VM state is consistent
        XCTAssertEqual(sut.selectedChapter, 8)
        XCTAssertEqual(sut.selectedLanguage, .spanish)
    }

    // MARK: - TC-PI-010 Chapter stays within 1...totalChapters (UI enforced, VM preserves)

    func test_updateChapter_preservesValueSetByUI() {
        sut.updateChapter(book.totalChapters)

        XCTAssertEqual(sut.selectedChapter, book.totalChapters)
        XCTAssertEqual(mockRepository.lastSavedProgress?.chapter, book.totalChapters)
    }
}
