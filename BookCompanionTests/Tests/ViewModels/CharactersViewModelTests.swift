// CharactersViewModelTests.swift
// BookCompanionTests
//
// Area 6 — AI Summaries & Analysis: CharactersViewModel cache, pagination, error handling.

import XCTest
@testable import BookCompanion

@MainActor
final class CharactersViewModelTests: XCTestCase {

    private var sut: CharactersViewModel!
    private var mockGenerator: MockSummaryGeneratorSpy!
    private var mockRepository: MockSummaryRepository!
    private var book: Book!

    override func setUp() async throws {
        try await super.setUp()
        book = TestFixtures.makeBook()
        mockGenerator = MockSummaryGeneratorSpy()
        mockRepository = MockSummaryRepository()
        sut = CharactersViewModel(
            book: book,
            language: .english,
            generator: mockGenerator,
            summaryRepository: mockRepository
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockGenerator = nil
        mockRepository = nil
        try await super.tearDown()
    }

    // MARK: - TC-CV-001 Cache hit: loads from repository without calling generator

    func test_loadCharacters_cacheHit_doesNotCallGenerator() async {
        let cached = TestFixtures.makeCharacterList(count: 3, bookId: book.id)
        mockRepository.seedCharacters(cached, bookId: book.id, chapter: 3, language: .english, length: .short)

        await sut.loadCharacters(chapter: 3, length: .short)

        XCTAssertFalse(mockGenerator.generateCharactersCalled, "Generator must not be called on cache hit")
        XCTAssertEqual(sut.characters.count, 3)
        XCTAssertTrue(sut.isCached)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - TC-CV-002 Cache miss: calls generator and returns first batch of 5

    func test_loadCharacters_cacheMiss_callsGeneratorAndPaginates() async {
        mockGenerator.charactersToReturn = TestFixtures.makeCharacterList(count: 7, bookId: book.id)

        await sut.loadCharacters(chapter: 3, length: .short)

        XCTAssertTrue(mockGenerator.generateCharactersCalled)
        XCTAssertEqual(sut.characters.count, 5, "First page must be limited to 5")
        XCTAssertTrue(sut.hasMore, "hasMore must be true when more characters exist")
        XCTAssertFalse(sut.isCached)
    }

    // MARK: - TC-CV-003 Load more appends next batch

    func test_loadMoreCharacters_appendsNextBatch() async {
        mockGenerator.charactersToReturn = TestFixtures.makeCharacterList(count: 7, bookId: book.id)

        await sut.loadCharacters(chapter: 3, length: .short)
        XCTAssertEqual(sut.characters.count, 5)

        await sut.loadMoreCharacters(chapter: 3, length: .short)
        XCTAssertEqual(sut.characters.count, 7, "Second page should append remaining 2")
        XCTAssertFalse(sut.hasMore, "hasMore must be false when all characters are loaded")
    }

    // MARK: - TC-CV-004 loadMoreCharacters is a no-op when hasMore is false

    func test_loadMoreCharacters_whenHasMoreFalse_doesNothing() async {
        mockGenerator.charactersToReturn = TestFixtures.makeCharacterList(count: 3, bookId: book.id)

        await sut.loadCharacters(chapter: 1, length: .short)
        XCTAssertFalse(sut.hasMore)

        let callCountBefore = mockRepository.loadCharactersCallCount
        await sut.loadMoreCharacters(chapter: 1, length: .short)
        XCTAssertEqual(mockRepository.loadCharactersCallCount, callCountBefore, "No additional load should occur")
    }

    // MARK: - TC-CV-005 Generator error sets error state

    func test_loadCharacters_generatorError_setsErrorState() async {
        mockGenerator.throwError = AIError.requestFailed

        await sut.loadCharacters(chapter: 1, length: .short)

        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.characters.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.hasMore)
    }

    // MARK: - TC-CV-006 Complete set is saved to cache after first load

    func test_loadCharacters_savesCompleteCacheAfterFirstLoad() async {
        let characters = TestFixtures.makeCharacterList(count: 6, bookId: book.id)
        mockGenerator.charactersToReturn = characters

        await sut.loadCharacters(chapter: 2, length: .short)

        XCTAssertTrue(mockRepository.saveCharactersCalled, "All characters must be saved to cache after first load")
    }

    // MARK: - TC-CV-007 Reset state on new loadCharacters call

    func test_loadCharacters_resetsPreviousState() async {
        mockGenerator.charactersToReturn = TestFixtures.makeCharacterList(count: 7, bookId: book.id)
        await sut.loadCharacters(chapter: 1, length: .short)

        // Second call with no cache
        mockGenerator.charactersToReturn = TestFixtures.makeCharacterList(count: 2, bookId: book.id)
        await sut.loadCharacters(chapter: 2, length: .short)

        XCTAssertEqual(sut.characters.count, 2, "Previous results must be cleared")
        XCTAssertEqual(sut.currentOffset, 0)
    }

    // MARK: - TC-CV-008 Empty generator response sets hasMore false

    func test_loadCharacters_emptyResponse_hasMoreFalse() async {
        mockGenerator.charactersToReturn = []

        await sut.loadCharacters(chapter: 1, length: .short)

        XCTAssertTrue(sut.characters.isEmpty)
        XCTAssertFalse(sut.hasMore)
        XCTAssertFalse(sut.isLoading)
    }
}
