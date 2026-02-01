//
//  ProgressInputViewModel.swift
//  BookCompanion
//
//  Created by Shree on 01/02/2026.
//
import Foundation
import Combine


@MainActor
final class ProgressInputViewModel: ObservableObject {

    @Published var selectedLanguage: Language
    @Published var selectedChapter: Int

    let book: Book

    private let repository: ProgressRepository
    private var hasLoadedInitialState = false

    init(
        book: Book,
        repository: ProgressRepository
    ) {
        self.book = book
        self.repository = repository

        if let saved = repository.loadProgress(for: book.id.uuidString) {
            self.selectedLanguage = saved.language
            self.selectedChapter = saved.chapter
        } else {
            self.selectedLanguage = book.language
            self.selectedChapter = 1
        }

        self.hasLoadedInitialState = true
    }

    func updateLanguage(_ language: Language) {
        selectedLanguage = language
        saveIfReady()
    }

    func updateChapter(_ chapter: Int) {
        selectedChapter = chapter
        saveIfReady()
    }

    func saveOnExit() {
        save()
    }

    private func saveIfReady() {
        guard hasLoadedInitialState else { return }
        save()
    }

    private func save() {
        let progress = ReadingProgress(
            id: UUID(),
            bookId: book.id,
            chapter: selectedChapter,
            language: selectedLanguage,
            updatedAt: Date()
        )

        repository.saveProgress(progress)
    }
}

