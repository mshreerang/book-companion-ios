import Foundation
import Combine

@MainActor
final class SummaryViewModel: ObservableObject {

    @Published private(set) var summary: BookSummary?
    @Published private(set) var characters: [BookCharacter] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isCached = false
    @Published private(set) var error: Error?

    private let book: Book
    private let language: Language
    private let length: SummaryLength  // ✅ Add this
    private let generator: SummaryGenerator
    private let summaryRepository: SummaryRepository

    init(
        book: Book,
        language: Language,
        length: SummaryLength,  // ✅ Add this parameter
        generator: SummaryGenerator,
        summaryRepository: SummaryRepository
    ) {
        self.book = book
        self.language = language
        self.length = length  // ✅ Store it
        self.generator = generator
        self.summaryRepository = summaryRepository
    }

    func generate(chapter: Int) async {
        isLoading = true
        isCached = false
        error = nil
        
        // 1️⃣ Try cache first (now includes length in key)
        if let cachedSummary = summaryRepository.loadSummary(
            bookId: book.id,
            chapter: chapter,
            language: language,
            length: length  // ✅ Add length to cache key
        ) {
            print("✅ Loaded from cache: Chapter \(chapter)")
            self.summary = cachedSummary
            
            // ✅ Load cached characters too
            if let cachedCharacters = summaryRepository.loadCharacters(
                bookId: book.id,
                chapter: chapter,
                language: language,
                length: length  // ✅ Add length to cache key
            ) {
                print("✅ Loaded characters from cache")
                self.characters = cachedCharacters
            } else {
                self.characters = []
            }
            
            self.isCached = true
            self.isLoading = false
            return
        }
        print("⚠️ No cache found, generating new summary for Chapter \(chapter)") 
        // 2️⃣ Otherwise generate
        isLoading = true
        defer { isLoading = false }
        
        do {
            let generatedSummary = try await generator.generateSummary(
                book: book,
                chapter: chapter,
                language: language,
                length: length  // ✅ Pass length to generator
            )
            
            let generatedCharacters = try await generator.generateCharacters(
                book: book,
                chapter: chapter,
                language: language
            )
            
            // ✅ Save both
            summaryRepository.saveSummary(generatedSummary)
            summaryRepository.saveCharacters(
                generatedCharacters,
                bookId: book.id,
                chapter: chapter,
                language: language,
                length: length  // ✅ Add length to cache key
            )
            
            self.summary = generatedSummary
            self.characters = generatedCharacters
            self.isCached = false
            self.error = nil
            
        } catch {
            summary = nil
            characters = []
            self.error = error
        }
    }

    func regenerate(chapter: Int) async {
        isLoading = true
        isCached = false
        error = nil
        defer { isLoading = false }
        
        do {
            let generatedSummary = try await generator.generateSummary(
                book: book,
                chapter: chapter,
                language: language,
                length: length  // ✅ Pass length to generator
            )
            
            let generatedCharacters = try await generator.generateCharacters(
                book: book,
                chapter: chapter,
                language: language
            )
            
            // ✅ Save both
            summaryRepository.saveSummary(generatedSummary)
            summaryRepository.saveCharacters(
                generatedCharacters,
                bookId: book.id,
                chapter: chapter,
                language: language,
                length: length  // ✅ Add length to cache key
            )
            
            self.summary = generatedSummary
            self.characters = generatedCharacters
            self.error = nil
            
        } catch {
            summary = nil
            characters = []
            self.error = error
        }
    }
}
