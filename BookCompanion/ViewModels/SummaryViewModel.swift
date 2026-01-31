import Foundation
import Combine

@MainActor
final class SummaryViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var summary: Summary?
    @Published var characters: [BookCharacter] = []

    func generate(book: Book, chapter: Int) async {
        isLoading = true

        // TODO: Replace with real AI call
        summary = Summary(
            id: UUID(),
            bookId: book.id,
            progressId: UUID(),
            content: "This is a placeholder summary up to chapter \(chapter).",
            language: book.language,
            generatedAt: Date()
        )

        characters = []
        isLoading = false
    }
}
