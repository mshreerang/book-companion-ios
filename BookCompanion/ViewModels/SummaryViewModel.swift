import Foundation
import SwiftUI
import Combine

@MainActor
class SummaryViewModel: ObservableObject {
    
    @Published var summary: BookSummary?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isCached = false
    
    // ✅ NEW: Streaming state
    @Published var streamingText = ""
    @Published var isStreaming = false
    
    private let book: Book
    private let language: Language
    private let length: SummaryLength
    private let generator: SummaryGenerator
    private let summaryRepository: SummaryRepository
    private var isLoadingCharacters = false
    init(
        book: Book,
        language: Language,
        length: SummaryLength,
        generator: SummaryGenerator,
        summaryRepository: SummaryRepository
    ) {
        self.book = book
        self.language = language
        self.length = length
        self.generator = generator
        self.summaryRepository = summaryRepository
    }
    
    // ✅ STREAMING GENERATION
    func generate(chapter: Int) async {
        isLoading = true
        isStreaming = true
        streamingText = ""
        error = nil
        isCached = false
        
        // Check cache first
        if let cachedSummary = loadCachedSummary(chapter: chapter) {
            // Animate cached summary (simulate streaming for consistency)
            await animateCachedSummary(cachedSummary)
            return
        }
        
        do {
            // Stream new summary from API
            try await streamSummary(chapter: chapter)
        } catch {
            self.error = error
            self.isLoading = false
            self.isStreaming = false
        }
    }
    
    // ✅ REGENERATE (force new generation, skip cache)
    func regenerate(chapter: Int) async {
        isLoading = true
        isStreaming = true
        streamingText = ""
        error = nil
        isCached = false
        
        do {
            try await streamSummary(chapter: chapter)
        } catch {
            self.error = error
            self.isLoading = false
            self.isStreaming = false
        }
    }
    
    // ✅ CORE STREAMING LOGIC
    private func streamSummary(chapter: Int) async throws {
        guard let url = URL(string: "\(Config.apiEndpoint)/api/generate-summary") else {
            throw AIError.requestFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.appSecret, forHTTPHeaderField: "X-App-Secret")
        request.timeoutInterval = Config.summaryTimeoutSeconds
        
        let body: [String: Any] = [
            "bookTitle": book.title,
            "author": book.author,
            "chapter": chapter,
            "language": language.displayName,
            "length": length.rawValue,
            "stream": true  // ✅ Enable streaming
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📡 Streaming summary for chapter \(chapter)...")
        
        // ✅ STREAMING REQUEST
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.requestFailed
        }
        
        guard httpResponse.statusCode == 200 else {
            switch httpResponse.statusCode {
            case 401:
                throw AIError.unauthorized
            case 429:
                throw AIError.rateLimited
            default:
                throw AIError.requestFailed
            }
        }
        
        var fullSummary = ""
        
        // ✅ PROCESS STREAM LINE BY LINE
        for try await line in bytes.lines {
            // SSE format: "data: {json}\n\n"
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6)) // Remove "data: "
                
                if let data = jsonString.data(using: .utf8),
                   let event = try? JSONDecoder().decode(StreamEvent.self, from: data) {
                    
                    switch event.type {
                    case "chunk":
                        // ✅ UPDATE UI WITH CHUNK
                        if let content = event.content {
                            fullSummary += content
                            streamingText = fullSummary
                            
                            // Add small delay for smooth animation
                            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01s
                        }
                        
                    case "done":
                        // ✅ STREAMING COMPLETE
                        let summary = BookSummary(
                            id: UUID(),
                            bookId: book.id,
                            chapter: chapter,
                            progressId: UUID(),
                            content: event.summary ?? fullSummary,
                            language: language,
                            length: length,
                            generatedAt: Date()
                        )
                        
                        // Save to cache
                        saveSummaryToCache(summary, chapter: chapter)
                        
                        // Update UI
                        self.summary = summary
                        self.isLoading = false
                        self.isStreaming = false
                        self.isCached = false
                        
                        print("✅ Summary streaming complete!")
                      
                        
                    default:
                        break
                    }
                }
            }
        }
    }
    
    // ✅ ANIMATE CACHED SUMMARY (simulate streaming for consistency)
    private func animateCachedSummary(_ summary: BookSummary) async {
        isCached = true
        
        // Split into words
        let words = summary.content.split(separator: " ")
        var currentText = ""
        
        // Animate word-by-word (faster than real streaming)
        for word in words {
            currentText += word + " "
            streamingText = currentText
            
            // Fast animation (20ms per word)
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        
        // Set final summary
        self.summary = summary
        self.isLoading = false
        self.isStreaming = false
     
    }
    
  
    // MARK: - Cache Management
    
    private func loadCachedSummary(chapter: Int) -> BookSummary? {
        return summaryRepository.loadSummary(
            bookId: book.id,
            chapter: chapter,
            language: language,
            length: length
        )
    }
    
    private func saveSummaryToCache(_ summary: BookSummary, chapter: Int) {
        summaryRepository.saveSummary(summary)
    }
    
        
}

// ✅ STREAM EVENT MODEL
struct StreamEvent: Codable {
    let type: String
    let content: String?
    let summary: String?
}
