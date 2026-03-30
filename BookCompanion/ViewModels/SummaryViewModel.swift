import Foundation
import SwiftUI
import Combine

@MainActor
class SummaryViewModel: ObservableObject {
    
    @Published var summary: BookSummary?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isCached = false
    
    // Streaming state
    @Published var streamingText = ""
    @Published var isStreaming = false

    // Paywall + quota nudge state
    // PaywallView is shown ONLY on HTTP 429 — never on any other error.
    @Published var showPaywall = false
    @Published var paywallTriggerReason = ""
    @Published var showQuotaNudge = false
    @Published var quotaUsed: Int? = nil
    @Published var quotaLimit: Int? = nil

    // ── Vani TTS Player ───────────────────────────────────────────────────────
    // Observed by SummaryView to conditionally show ActiveNarratorView.
    // Pre-warm fires on 'done' event with full summary text — never with a partial chunk.
    @Published var vaniPlayer = VaniPlayerViewModel()
    
    private let book: Book
    private let language: Language
    private let length: SummaryLength
    private let generator: SummaryGenerator
    private let summaryRepository: SummaryRepository
    private let allBooks: [Book]   // for series context injection
    private var isLoadingCharacters = false

    init(
        book: Book,
        language: Language,
        length: SummaryLength,
        generator: SummaryGenerator,
        summaryRepository: SummaryRepository,
        allBooks: [Book] = []
    ) {
        self.book = book
        self.language = language
        self.length = length
        self.generator = generator
        self.summaryRepository = summaryRepository
        self.allBooks = allBooks
    }
    
    // ✅ STREAMING GENERATION
    func generate(chapter: Int) async {
        // ✅ ANALYTICS: Track summary request
        AnalyticsManager.shared.track(
            event: "summary_requested",
            properties: [
                "book_title": book.title,
                "author": book.author,
                "chapter": chapter,
                "language": language.displayName,
                "length": length.rawValue
            ]
        )
        
        isLoading = true
        isStreaming = true
        streamingText = ""
        error = nil
        isCached = false

        // Reset Vani player for the new chapter
        vaniPlayer.reset()
        
        // Check cache first
        if let cachedSummary = loadCachedSummary(chapter: chapter) {
            // ✅ ANALYTICS: Track cache hit
            AnalyticsManager.shared.track(
                event: "summary_loaded_from_cache",
                properties: [
                    "book_title": book.title,
                    "chapter": chapter
                ]
            )
            
            // Animate cached summary (simulate streaming for consistency)
            await animateCachedSummary(cachedSummary, chapter: chapter)
            return
        }
        
        do {
            // Stream new summary from API
            try await streamSummary(chapter: chapter)
        } catch let aiError as AIError {
            // Quota exceeded — show paywall, not an error message.
            // PaywallView appears ONLY on explicit 429, never on network errors.
            if case .quotaExceeded(let message) = aiError {
                self.paywallTriggerReason = message
                self.showPaywall = true
                self.isLoading = false
                self.isStreaming = false
            } else {
                self.error = aiError
                self.isLoading = false
                self.isStreaming = false
            }
            AnalyticsManager.shared.track(
                event: "summary_failed",
                properties: [
                    "book_title": book.title,
                    "chapter": chapter,
                    "error": aiError.localizedDescription
                ]
            )
        } catch {
            self.error = error
            self.isLoading = false
            self.isStreaming = false
            AnalyticsManager.shared.track(
                event: "summary_failed",
                properties: [
                    "book_title": book.title,
                    "chapter": chapter,
                    "error": error.localizedDescription
                ]
            )
        }
    }
    
    // ✅ REGENERATE (force new generation, skip cache)
    func regenerate(chapter: Int) async {
        // ✅ ANALYTICS: Track regeneration request
        AnalyticsManager.shared.track(
            event: "summary_regenerated",
            properties: [
                "book_title": book.title,
                "chapter": chapter
            ]
        )
        
        isLoading = true
        isStreaming = true
        streamingText = ""
        error = nil
        isCached = false

        // Reset Vani player for regeneration
        vaniPlayer.reset()
        
        do {
            try await streamSummary(chapter: chapter)
        } catch {
            self.error = error
            self.isLoading = false
            self.isStreaming = false
            
            // ✅ ANALYTICS: Track failure
            AnalyticsManager.shared.track(
                event: "summary_failed",
                properties: [
                    "book_title": book.title,
                    "chapter": chapter,
                    "error": error.localizedDescription,
                    "is_regeneration": true
                ]
            )
        }
    }
    
    // ✅ CORE STREAMING LOGIC
    private func streamSummary(chapter: Int) async throws {
        let startTime = Date()
        
        guard let url = URL(string: "\(Config.apiEndpoint)/api/generate-summary") else {
            throw AIError.requestFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Get user token from Keychain
        if let userToken = KeychainManager.shared.getUserToken() {
            request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        } else {
            throw AuthError.invalidResponse
        }
        request.timeoutInterval = Config.summaryTimeoutSeconds
        
        // Build series context if this book is part of a series
        // SeriesManager.buildAIContext returns nil for standalone books — no overhead
        let seriesContext = SeriesManager.shared.buildAIContext(for: book, allBooks: allBooks)

        var body: [String: Any] = [
            "bookTitle": book.title,
            "author": book.author,
            "chapter": chapter,
            "language": language.displayName,
            "length": length.rawValue,
            "bookType": book.bookType.rawValue,
            "stream": true
        ]

        // Inject series context when available — backend injects it into the prompt
        if let ctx = seriesContext,
           let encoded = try? JSONEncoder().encode(ctx),
           let dict = try? JSONSerialization.jsonObject(with: encoded) as? [String: Any] {
            body["seriesContext"] = dict
            print("📚 Series context injected: \(ctx.seriesName) Book \(ctx.bookPosition), \(ctx.completedBooks.count) prior book(s)")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📡 Streaming summary for chapter \(chapter)...")
        
        // ✅ STREAMING REQUEST
        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.requestFailed
        }

        // ✅ Check status code BEFORE reading stream
        if httpResponse.statusCode == 429 {
            // Read error response
            var errorText = ""
            for try await line in bytes.lines {
                errorText += line
            }
            
            // Try to parse JSON error
            if let errorData = errorText.data(using: .utf8),
               let errorJson = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any],
               let errorMessage = errorJson["message"] as? String {
                
                // ✅ ANALYTICS: Track quota exceeded
                AnalyticsManager.shared.track(
                    event: "quota_limit_reached",
                    properties: [
                        "book_title": book.title,
                        "chapter": chapter,
                        "type": "summary"
                    ]
                )
                
                throw AIError.quotaExceeded(errorMessage)
            }
            
            // ✅ ANALYTICS: Track rate limit
            AnalyticsManager.shared.track(
                event: "rate_limit_reached",
                properties: [
                    "book_title": book.title,
                    "chapter": chapter,
                    "type": "summary"
                ]
            )
            
            throw AIError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            switch httpResponse.statusCode {
            case 401:
                throw AIError.unauthorized
            default:
                throw AIError.requestFailed
            }
        }

        var fullSummary = ""

        // ✅ PROCESS STREAM LINE BY LINE (only reaches here if 200)
        for try await line in bytes.lines {
           if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6)) // Remove "data: "
                
                if let data = jsonString.data(using: .utf8),
                   let event = try? JSONDecoder().decode(StreamEvent.self, from: data) {
                    
                    switch event.type {
                    case "chunk":
                        if let content = event.content {
                            fullSummary += content
                            streamingText = fullSummary
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
                        
                        // Update UI with final canonical text
                        self.summary = summary
                        self.streamingText = summary.content
                        self.isLoading = false
                        self.isStreaming = false
                        self.isCached = false

                        // Fire Vani pre-warm with FULL summary text.
                        // Streaming is done so TTS gets the complete text.
                        // Vani pre-warm is user-triggered — tap the idle bar to start

                        // Show nudge toast when user has 1 or 2 free summaries remaining
                        // Update quota state for counter display
                        if let quota = event.quota,
                        let isPro = quota["isPro"] as? Bool,
                            !isPro {
                                    let used = quota["used"] as? Int
                                    let limit = quota["limit"] as? Int
                                    let remaining = quota["remaining"] as? Int ?? 5
                                    self.quotaUsed = used
                                    self.quotaLimit = limit
                                        if remaining <= 2 {
                                                        self.showQuotaNudge = true
                                                    }
                                                }
                        
                        // ✅ ANALYTICS: Track success
                        let generationTime = Date().timeIntervalSince(startTime)
                        AnalyticsManager.shared.track(
                            event: "summary_generated",
                            properties: [
                                "book_title": book.title,
                                "author": book.author,
                                "chapter": chapter,
                                "language": language.displayName,
                                "length": length.rawValue,
                                "generation_time_seconds": generationTime,
                                "content_length": summary.content.count
                            ]
                        )
                        
                        print("✅ Summary streaming complete!")
                      
                        
                    default:
                        break
                    }
                }
            }
        }
    }
    
    // ✅ ANIMATE CACHED SUMMARY (simulate streaming for consistency)
    private func animateCachedSummary(_ summary: BookSummary, chapter: Int = 0) async {
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

        // Vani pre-warm with full cached summary text
        // Vani pre-warm is user-triggered — tap the idle bar to start
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
    let quota: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case type, content, summary, quota
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        // Decode quota as raw JSON since it contains mixed types
        if let quotaData = try? container.decodeIfPresent(Data.self, forKey: .quota),
           let dict = try? JSONSerialization.jsonObject(with: quotaData) as? [String: Any] {
            quota = dict
        } else {
            quota = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encodeIfPresent(summary, forKey: .summary)
    }
}
