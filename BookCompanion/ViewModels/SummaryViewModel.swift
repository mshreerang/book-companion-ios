import Foundation
import Combine

@MainActor
final class SummaryViewModel: ObservableObject {

    @Published private(set) var summary: BookSummary?
    @Published private(set) var characters: [BookCharacter] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isCached = false

    private let book: Book
    private let language: Language
    private let generator: SummaryGenerator
    private let summaryRepository: SummaryRepository

    init(
        book: Book,
        language: Language,
        generator: SummaryGenerator,
        summaryRepository: SummaryRepository
    ) {
        self.book = book
        self.language = language
        self.generator = generator
        self.summaryRepository = summaryRepository
    }

    func generate(chapter: Int) async {
        isLoading = false
        isCached = false

        // 1️⃣ Try cache first
        if let cached = summaryRepository.loadSummary(
            bookId: book.id,
            chapter: chapter,
            language: language
        ) {
            self.summary = cached
            self.characters = [] // or cached characters later
            self.isCached = true
            self.isLoading = false
            return
        }

        // 2️⃣ Otherwise generate
        isLoading = true
        defer { isLoading = false }

        do {
            let generated = try await generator.generateSummary(
                book: book,
                chapter: chapter,
                language: language
            )

            summaryRepository.saveSummary(generated)
            self.summary = generated
            self.isCached = false
            self.characters = try await generator.generateCharacters(
                book: book,
                chapter: chapter,
                language: language
            )

        } catch {
            summary = nil
            characters = []
        }
    }
    func regenerate(chapter: Int) async {
        isLoading = true
        isCached = false
        defer { isLoading = false }

        do {
            let generated = try await generator.generateSummary(
                book: book,
                chapter: chapter,
                language: language
            )
           summaryRepository.saveSummary(generated)
            self.summary = generated

            self.characters = try await generator.generateCharacters(
                book: book,
                chapter: chapter,
                language: language
            )

        } catch {
            summary = nil
            characters = []
        }
    }

}
