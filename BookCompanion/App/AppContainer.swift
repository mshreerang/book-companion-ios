//
//  AppContainer.swift
//  BookCompanion
//
//  Created by Shree on 01/02/2026.
//
final class AppContainer {

    private lazy var bookRepository: BookRepository =
        MockBookRepository()
    private lazy var progressRepository: ProgressRepository =
        UserDefaultsProgressRepository()
    private lazy var summaryGenerator: SummaryGenerator =
        MockSummaryGenerator()
    private lazy var summaryRepository: SummaryRepository =
        UserDefaultsSummaryRepository()

    func makeSummaryViewModel(book: Book, language: Language) -> SummaryViewModel {
        SummaryViewModel(
            book: book,
            language: language,
            generator: summaryGenerator,
            summaryRepository: summaryRepository
        )
    }
    func makeBookSearchViewModel() -> BookSearchViewModel {
        BookSearchViewModel(repository: bookRepository)
    }
    
    func makeProgressInputViewModel(book: Book) -> ProgressInputViewModel {
        ProgressInputViewModel(
            book: book,
            repository: progressRepository
        )
    }
}
