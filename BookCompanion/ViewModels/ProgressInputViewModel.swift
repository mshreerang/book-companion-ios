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
    @Published var selectedLength: SummaryLength = .short

    let book: Book

    private let repository: ProgressRepository
    private let bookManager: BookManager          // ← drives cloud sync
    private var hasLoadedInitialState = false
    private var currentProgressId: UUID

    init(
        book: Book,
        repository: ProgressRepository,
        bookManager: BookManager
    ) {
        self.book = book
        self.repository = repository
        self.bookManager = bookManager

        if let saved = repository.loadProgress(for: book.id.uuidString) {
            self.selectedLanguage = saved.language
            self.selectedChapter = saved.chapter
            self.currentProgressId = saved.id
        } else {
            self.selectedLanguage = book.language
            self.selectedChapter = book.readingProgress?.chapter ?? 1
            self.currentProgressId = UUID()
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
        // Length is per-session only — no need to persist
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
            id: currentProgressId,
            bookId: book.id,
            chapter: selectedChapter,
            language: selectedLanguage,
            updatedAt: Date()
        )

        // Local persistence only — cheap, instant, works offline.
        // Cloud sync is intentional: call syncChapterToCloud() only when
        // the user actually acts on a chapter (summary or characters).
        repository.saveProgress(progress)

        // Also update in-memory book array so UI stays consistent,
        // but WITHOUT triggering the background network call.
        bookManager.updateProgressInMemory(progress, for: book.id)
    }

    /// Call this when the user generates a summary or views characters.
    /// Persists the current chapter to Supabase — one call, intentional action.
    /// Exposes all library books for series context injection in character/summary calls.
    var allBooks: [Book] { bookManager.books }

    func syncChapterToCloud() {
        let progress = ReadingProgress(
            id: currentProgressId,
            bookId: book.id,
            chapter: selectedChapter,
            language: selectedLanguage,
            updatedAt: Date()
        )
        bookManager.saveProgress(progress, for: book.id)
    }
}
