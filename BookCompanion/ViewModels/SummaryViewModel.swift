import Foundation
import Combine

@MainActor
final class SummaryViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var summary: BookSummary?
    @Published var characters: [BookCharacter] = []
    private let progressStore = ProgressStore.shared
    private let generator: SummaryGenerating

    init(generator: SummaryGenerating) {
        self.generator = generator
    }

    func generate(book: Book, chapter: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            summary = try await generator.generateSummary(book: book, chapter: chapter)
            characters = try await generator.generateCharacters(book: book, chapter: chapter)

            let progress = ReadingProgress(
                id: UUID(),
                bookId: book.id,
                chapter: chapter,
                language: book.language,
                updatedAt: Date()
            )

            progressStore.save(progress)

        } catch {
            summary = nil
            characters = []
        }
    }

}

