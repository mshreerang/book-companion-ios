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
    @Published var selectedLength: SummaryLength = .medium  

    let book: Book

    private let repository: ProgressRepository
    private var hasLoadedInitialState = false
    private var currentProgressId: UUID  // ✅ Fixed: Store progress ID

    init(
        book: Book,
        repository: ProgressRepository
    ) {
        self.book = book
        self.repository = repository

        if let saved = repository.loadProgress(for: book.id.uuidString) {
            self.selectedLanguage = saved.language
            self.selectedChapter = saved.chapter
            self.currentProgressId = saved.id  // ✅ Reuse existing ID
        } else {
            self.selectedLanguage = book.language
            self.selectedChapter = 1
            self.currentProgressId = UUID()  // ✅ Create once
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
    
    func updateLength(_ length: SummaryLength) {
        selectedLength = length
        // No need to save - length is per-session preference
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
            id: currentProgressId,  // ✅ Fixed: Reuse same ID
            bookId: book.id,
            chapter: selectedChapter,
            language: selectedLanguage,
            updatedAt: Date()
        )

        repository.saveProgress(progress)
    }
}
