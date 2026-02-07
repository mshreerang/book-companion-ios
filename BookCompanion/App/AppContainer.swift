//
//  AppContainer.swift
//  BookCompanion
//
//  Created by Shree on 01/02/2026.
//

import Foundation

final class AppContainer {
    
    // MARK: - Managers
    
    let settingsManager = SettingsManager()
    let bookManager = BookManager()  // ✅ User's library
    
    // MARK: - Repositories
    
    // We can remove bookRepository since we're using BookManager now
    
    private lazy var progressRepository: ProgressRepository =
        UserDefaultsProgressRepository()
    
    private lazy var summaryRepository: SummaryRepository =
        UserDefaultsSummaryRepository()
    
    // MARK: - Generators
    
    /// Smart generator selection based on AI mode setting
    private var summaryGenerator: SummaryGenerator {
        if settingsManager.settings.isAIEnabled {
            return ServerAISummaryGenerator(
                endpoint: Config.apiEndpoint,
                appSecret: Config.appSecret
            )
        } else {
            return MockSummaryGenerator()
        }
    }
    
    // MARK: - View Model Factories
    
    func makeSummaryViewModel(
        book: Book,
        language: Language,
        length: SummaryLength
    ) -> SummaryViewModel {
        SummaryViewModel(
            book: book,
            language: language,
            length: length,
            generator: summaryGenerator,
            summaryRepository: summaryRepository
        )
    }
    
    func makeBookSearchViewModel() -> BookSearchViewModel {
        BookSearchViewModel(bookManager: bookManager)
    }
    
    func makeProgressInputViewModel(book: Book) -> ProgressInputViewModel {
        ProgressInputViewModel(
            book: book,
            repository: progressRepository
        )
    }
    func makeCharactersViewModel(
        book: Book,
        language: Language
    ) -> CharactersViewModel {
        CharactersViewModel(
            book: book,
            language: language,
            generator: summaryGenerator,
            summaryRepository: summaryRepository
        )
    }
}
