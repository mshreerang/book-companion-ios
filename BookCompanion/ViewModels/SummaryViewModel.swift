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
            await animateCachedSummary(cachedSummary)
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

                        // Show nudge toast when user has 1 free summary remaining
                        if let quota = event.quota,
                           let remaining = quota["remaining"] as? Int,
                           remaining == 1,
                           let isPro = quota["isPro"] as? Bool,
                           !isPro {
                            self.showQuotaNudge = true
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
