// MockProgressRepository.swift
// BookCompanionTests — Shared Mock Infrastructure

import Foundation
@testable import BookCompanion

final class MockProgressRepository: ProgressRepository {

    private var store: [String: ReadingProgress] = [:]

    private(set) var saveProgressCalled = false
    private(set) var lastSavedProgress: ReadingProgress?

    func loadProgress(for bookId: String) -> ReadingProgress? {
        store[bookId]
    }

    func saveProgress(_ progress: ReadingProgress) {
        saveProgressCalled = true
        lastSavedProgress = progress
        store[progress.bookId.uuidString] = progress
    }

    func seed(_ progress: ReadingProgress) {
        store[progress.bookId.uuidString] = progress
    }
}
