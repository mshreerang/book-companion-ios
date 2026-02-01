//
//  BookSearchViewModel.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//

import Combine

final class BookSearchViewModel: ObservableObject {

    @Published var searchText: String = ""
    @Published private(set) var results: [Book] = []

    private let repository: BookRepository

    init(repository: BookRepository) {
        self.repository = repository
        self.results = repository.fetchBooks()
    }

    func search() {
        // v0.1 – no-op (search is client-side for now)
    }
}
