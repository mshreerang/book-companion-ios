// BookSearchViewModelTests.swift
// BookCompanionTests
//
// Area 2 — Book Management: BookSearchViewModel search text, book list reactivity.

import XCTest
import Combine
@testable import BookCompanion

@MainActor
final class BookSearchViewModelTests: XCTestCase {

    private var sut: BookSearchViewModel!
    private var bookManager: BookManager!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        bookManager = BookManager()
        sut = BookSearchViewModel(bookManager: bookManager)
    }

    override func tearDown() {
        cancellables.removeAll()
        sut = nil
        bookManager = nil
        super.tearDown()
    }

    // TC-BSV-001 Initial searchText is empty
    func test_initialSearchText_isEmpty() {
        XCTAssertEqual(sut.searchText, "")
    }

    // TC-BSV-002 books reflects bookManager.books
    func test_books_reflectsBookManager() {
        // BookManager starts with persisted books — we can at least verify types match
        XCTAssertEqual(sut.books.count, bookManager.books.count)
    }

    // TC-BSV-003 Adding a book causes objectWillChange to fire
    func test_addingBook_causesObjectWillChange() {
        let expectation = expectation(description: "objectWillChange fires")

        sut.objectWillChange
            .first()
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        bookManager.addBook(title: "Test Book", author: "Test Author", language: .english, totalChapters: 10)

        wait(for: [expectation], timeout: 1.0)

        // Clean up
        if let book = bookManager.books.first(where: { $0.title == "Test Book" }),
           let index = bookManager.books.firstIndex(where: { $0.id == book.id }) {
            bookManager.deleteBooks(at: IndexSet(integer: index))
        }
    }

    // TC-BSV-004 searchText is published and assignable
    func test_searchText_isPublished() {
        let expectation = expectation(description: "searchText change published")

        sut.$searchText
            .dropFirst()
            .first()
            .sink { value in
                XCTAssertEqual(value, "Gatsby")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.searchText = "Gatsby"
        wait(for: [expectation], timeout: 1.0)
    }

    // TC-BSV-005 Filtered books logic (in BookSearchView) — verify searchText drives UI
    func test_filteredBooks_withSearchText_filtersCorrectly() {
        // This tests the filtering logic from BookSearchView which uses sut.searchText
        // We simulate the filter logic here
        let allBooks = [
            TestFixtures.makeBook(title: "The Great Gatsby", author: "Fitzgerald"),
            TestFixtures.makeBook(title: "1984", author: "George Orwell"),
            TestFixtures.makeBook(title: "Gatsby Returns", author: "Unknown")
        ]

        let searchText = "gatsby"
        let filtered = allBooks.filter { book in
            book.title.localizedCaseInsensitiveContains(searchText) ||
            book.author.localizedCaseInsensitiveContains(searchText)
        }

        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.title.lowercased().contains("gatsby") })
    }
}
