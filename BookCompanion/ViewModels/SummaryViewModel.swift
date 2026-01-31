import Foundation
import Combine

@MainActor
final class SummaryViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var summary: BookSummary?
    @Published var characters: [BookCharacter] = []

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
        } catch {
            summary = nil
            characters = []
        }
    }
}

