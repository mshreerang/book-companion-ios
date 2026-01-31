//
//  BookSearchViewModel.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
import Combine

final class BookSearchViewModel: ObservableObject {
@Published var searchText: String = ""
    @Published var results: [Book] = MockData.books

func search() {
// v0.1: use mock data
    }
}

