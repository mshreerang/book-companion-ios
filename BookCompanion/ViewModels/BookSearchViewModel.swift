//
//  BookSearchViewModel.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//

import Combine

final class BookSearchViewModel: ObservableObject {
    
    @Published var searchText: String = ""
    
    private let bookManager: BookManager
    private var cancellables = Set<AnyCancellable>()
    
    var books: [Book] {
        bookManager.books
    }
    
    init(bookManager: BookManager) {
        self.bookManager = bookManager
        
        // Observe changes to bookManager
        bookManager.$books
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
