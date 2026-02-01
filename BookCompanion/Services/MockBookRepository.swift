//
//  MockBookRepository.swift
//  BookCompanion
//
//  Created by Shree on 01/02/2026.
//
final class MockBookRepository: BookRepository {

    func fetchBooks() -> [Book] {
        MockData.books
    }
}

