//
//  ProgressRepository.swift
//  BookCompanion
//
//  Created by Shree on 01/02/2026.
//
import Foundation

protocol ProgressRepository {
    func loadProgress(for bookId: String) -> ReadingProgress?
    func saveProgress(_ progress: ReadingProgress)
}

