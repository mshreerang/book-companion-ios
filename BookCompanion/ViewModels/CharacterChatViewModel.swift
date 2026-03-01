//
//  CharacterChatViewModel.swift
//  BookCompanion
//
//  Created by Shree on 27/02/2026.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Chat Stream Event
//
// Separate from SummaryViewModel's StreamEvent intentionally.
// Chat events carry extra fields (message, reason) that summary
// streaming doesn't need. Keeping them decoupled avoids breaking
// changes if either protocol evolves independently.

private struct ChatStreamEvent: Codable {
    let type: String        // "chunk" | "done" | "safety_block" | "safety_replaced" | "safety_end" | "quota_limit"
    let content: String?    // character response text (chunk / done / safety_replaced)
    let message: String?    // human-readable copy for safety_block / safety_end / quota_limit
}

// MARK: - CharacterChatViewModel

@MainActor
final class CharacterChatViewModel: ObservableObject {

    // MARK: Published state

    @Published var messages: [CharacterChatMessage] = []
    @Published var inputText: String = ""
    @Published var isStreaming: Bool = false     // true from send → until done/safety_replaced/error
    @Published var isAtLimit: Bool = false       // quota gate — shows upgrade card, amber UI
    @Published var isSafetyEnded: Bool = false   // safety_end — session permanently locked, no upgrade CTA
    @Published var error: String? = nil          // transient network/auth errors shown in UI

    // MARK: Private

    private let character: CharacterCard
    private let book: Book
    private let chapter: Int
    private let language: Language
    private let sessionKey: String

    // ID of the single in-flight streaming bubble.
    // Used to update content in-place via updateStreamingMessage().
    private var streamingMessageId: UUID? = nil

    // MARK: Typewriter engine
    // Network chunks land in `typewriterBuffer` as fast as they arrive.
    // A separate Task drains them character-by-character at a human pace,
    // so the UI feels like the character is thinking and speaking — not
    // a machine dumping text.
    private var typewriterBuffer: String = ""
    private var typewriterDisplayed: String = ""
    private var typewriterTask: Task<Void, Never>? = nil
    private var networkStreamDone: Bool = false

    // MARK: - Init

    init(
        character: CharacterCard,
        book: Book,
        chapter: Int,
        language: Language
    ) {
        self.character = character
        self.book = book
        self.chapter = chapter
        self.language = language
        self.sessionKey = ChatSessionStore.key(
            bookId: book.id,
            characterName: character.fullName
        )

        restoreOrGreet()
    }

    // MARK: - Session Restore / Greeting

    private func restoreOrGreet() {
        if let session = ChatSessionStore.load(key: sessionKey), !session.messages.isEmpty {
            // Restore previous session — user sees their conversation history
            messages = session.messages
            print("✅ CharacterChatViewModel: restored \(session.messages.count) messages")
        } else {
            // Fresh session — fetch a real in-character greeting from the backend
            Task { await fetchGreeting() }
        }
    }

    /// Streams a real in-character opening line from the backend.
    /// Uses the same SSE pipeline as sendMessage() but sends a special
    /// sentinel so the backend uses a greeting prompt instead of replying
    /// to a user message.
    @MainActor
    private func fetchGreeting() async {
        let placeholder = CharacterChatMessage.characterPlaceholder()
        streamingMessageId = placeholder.id
        messages = [placeholder]
        await streamResponse(userMessage: "__greeting__")
    }

    // MARK: - Send Message

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming, !isAtLimit, !isSafetyEnded else { return }

        inputText = ""
        error = nil

        // 1. Append user bubble immediately
        let userMessage = CharacterChatMessage.userMessage(text)
        messages.append(userMessage)

        // 2. Append streaming placeholder — the typing indicator
        let placeholder = CharacterChatMessage.characterPlaceholder()
        streamingMessageId = placeholder.id
        messages.append(placeholder)

        // 3. Persist before the network call so the user bubble survives a crash
        persistSession()

        // 4. Fire the SSE request
        Task {
            await streamResponse(userMessage: text)
        }
    }

    // MARK: - Core SSE Streaming

    @MainActor
    private func streamResponse(userMessage: String) async {
        isStreaming = true

        // Reset typewriter state for this new response
        typewriterBuffer = ""
        typewriterDisplayed = ""
        networkStreamDone = false
        typewriterTask?.cancel()
        typewriterTask = nil
        let startTime = Date()

        // Build request
        guard let url = URL(string: "\(Config.apiEndpoint)/api/character-chat") else {
            handleNetworkError("Invalid endpoint URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Config.chatTimeoutSeconds

        guard let userToken = KeychainManager.shared.getUserToken() else {
            handleNetworkError("Not signed in")
            return
        }
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")

        // API payload — mirrors the structure specified in the PRD §11 backend spec
        let body: [String: Any] = [
            "bookTitle":      book.title,
            "author":         book.author,
            "chapter":        chapter,
            "language":       language.displayName,
            "characterName":  character.fullName,
            "characterRole":  character.role ?? "Character",
            "userMessage":    userMessage,
            // Send conversation history so the LLM has context.
            // Filter to user/character only — system messages are never sent.
            "history":        apiHistory(),
            "stream":         true
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            handleNetworkError("Failed to encode request")
            return
        }
        request.httpBody = bodyData

        print("📡 CharacterChat: streaming response for \(character.fullName)...")

        // MARK: SSE stream

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                handleNetworkError("Invalid server response")
                return
            }

            // Rate limit (infrastructure-level, not quota)
            if httpResponse.statusCode == 429 {
                var errorText = ""
                for try await line in bytes.lines { errorText += line }

                let message: String
                if let data = errorText.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["message"] as? String {
                    message = msg
                } else {
                    message = "Too many requests. Please wait a moment."
                }

                AnalyticsManager.shared.track(
                    event: "character_rate_limited",
                    properties: ["character_name": character.fullName, "book_title": book.title]
                )

                removeStreamingPlaceholder()
                isStreaming = false
                error = message
                return
            }

            guard httpResponse.statusCode == 200 else {
                switch httpResponse.statusCode {
                case 401: handleNetworkError("Session expired. Please sign in again.")
                default:  handleNetworkError("Server error (\(httpResponse.statusCode)). Please try again.")
                }
                return
            }

            // MARK: Process stream line by line

            var fullResponse = ""

            for try await line in bytes.lines {
                guard line.hasPrefix("data: ") else { continue }

                let jsonString = String(line.dropFirst(6))
                guard let data = jsonString.data(using: .utf8),
                      let event = try? JSONDecoder().decode(ChatStreamEvent.self, from: data)
                else { continue }

                handleStreamEvent(event, fullResponse: &fullResponse, startTime: startTime)

                // Break out of the loop after terminal events
                if ["done", "safety_block", "safety_replaced", "safety_end", "quota_limit"]
                    .contains(event.type) { break }
            }

        } catch {
            // URLSession cancellation (view dismissed mid-stream) — not a user-visible error
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                print("ℹ️ CharacterChat: stream cancelled (view dismissed)")
                typewriterTask?.cancel()
                typewriterTask = nil
                removeStreamingPlaceholder()
                isStreaming = false
                return
            }

            handleNetworkError(error.localizedDescription)
        }
    }

    // MARK: - Stream Event Handler

    private func handleStreamEvent(
        _ event: ChatStreamEvent,
        fullResponse: inout String,
        startTime: Date
    ) {
        switch event.type {

        // ── Chunk ────────────────────────────────────────────────────────
        // Buffer the chunk — the typewriter engine drains it at human pace.
        case "chunk":
            guard let content = event.content else { return }
            fullResponse += content
            typewriterBuffer += content
            // Start the typewriter drain if not already running
            if typewriterTask == nil {
                startTypewriter()
            }

        // ── Done ─────────────────────────────────────────────────────────
        // Network stream finished and Tier 3 passed. Signal the typewriter
        // that no more chunks are coming so it can finalise when drained.
        case "done":
            networkStreamDone = true
            // The typewriter's completion handler calls finaliseStream()

            let latency = Date().timeIntervalSince(startTime)
            AnalyticsManager.shared.track(
                event: "character_response_received",
                properties: [
                    "book_title":       book.title,
                    "character_name":   character.fullName,
                    "chapter":          chapter,
                    "response_length":  fullResponse.count,
                    "latency_seconds":  latency,
                    "was_output_filtered": false
                ]
            )
            print("✅ CharacterChat: response complete (\(String(format: "%.2f", latency))s)")

        // ── Safety Replaced (Tier 3) ──────────────────────────────────────
        // Output filter flagged the assembled response.
        // Route the safe fallback through the typewriter too — still feels natural.
        case "safety_replaced":
            let fallback = event.content ?? "I got a bit carried away there. Let's keep this within our story."
            typewriterBuffer = fallback  // replace any partial buffer with the fallback
            typewriterDisplayed = ""
            networkStreamDone = true
            if typewriterTask == nil { startTypewriter() }

            AnalyticsManager.shared.track(
                event: "character_safety_output_replaced",
                properties: [
                    "book_title":     book.title,
                    "character_name": character.fullName,
                    "chapter":        chapter
                    // Never log the flagged content itself
                ]
            )

            let latency = Date().timeIntervalSince(startTime)
            AnalyticsManager.shared.track(
                event: "character_response_received",
                properties: [
                    "book_title":             book.title,
                    "character_name":         character.fullName,
                    "chapter":                chapter,
                    "response_length":        fallback.count,
                    "latency_seconds":        latency,
                    "was_output_filtered":    true
                ]
            )

        // ── Safety Block (Tier 1) ─────────────────────────────────────────
        // Input filter blocked the message before any LLM call.
        // No streaming placeholder was ever populated — remove it and
        // insert a system bubble with the safe refusal copy.
        case "safety_block":
            removeStreamingPlaceholder()
            isStreaming = false

            let refusal = event.message ?? "I can't engage with that topic. Let's talk about the story."
            messages.append(.safetyBlock(refusal))
            persistSession()

            AnalyticsManager.shared.track(
                event: "character_safety_block",
                properties: [
                    "book_title":     book.title,
                    "character_name": character.fullName,
                    "chapter":        chapter
                    // Never log the blocked input text
                ]
            )

        // ── Safety End (Tier 2) ───────────────────────────────────────────
        // The Safety Anchor in the system prompt triggered.
        // Session is permanently ended — input bar locked, no upgrade CTA.
        case "safety_end":
            removeStreamingPlaceholder()
            isStreaming = false
            isSafetyEnded = true

            let endMessage = event.message ?? "This conversation has ended."
            messages.append(.safetyEnd(endMessage))

            // Clear session — do not restore this conversation
            ChatSessionStore.clearSession(key: sessionKey)

            AnalyticsManager.shared.track(
                event: "character_safety_block",
                properties: [
                    "book_title":     book.title,
                    "character_name": character.fullName,
                    "chapter":        chapter,
                    "tier":           "tier_2_safety_anchor"
                ]
            )

        // ── Quota Limit ───────────────────────────────────────────────────
        // Business rule: free tier gate (5 messages on 2nd+ character).
        // Shows upgrade card. Different from rate limiting (infrastructure).
        case "quota_limit":
            removeStreamingPlaceholder()
            isStreaming = false
            isAtLimit = true

            let limitMessage = event.message ?? "You've reached the free message limit for this character. Upgrade to Pro to keep chatting."
            messages.append(.quotaLimit(limitMessage))
            persistSession()

            AnalyticsManager.shared.track(
                event: "quota_limit_reached",
                properties: [
                    "book_title":     book.title,
                    "character_name": character.fullName,
                    "chapter":        chapter,
                    "type":           "character_chat"
                ]
            )

        default:
            print("⚠️ CharacterChat: unknown event type '\(event.type)'")
        }
    }

    // MARK: - Report Conversation

    func submitReport(reason: String, detail: String?) async {
        guard let userToken = KeychainManager.shared.getUserToken() else { return }

        let snapshot = messages
            .suffix(5)
            .map { "\($0.role.rawValue): \($0.content)" }
            .joined(separator: "\n")

        guard let url = URL(string: "\(Config.apiEndpoint)/api/report-chat") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")

        // userId is hashed server-side — we send the raw ID over our own authenticated endpoint
        let body: [String: Any] = [
            "bookTitle":            book.title,
            "characterName":        character.fullName,
            "reportReason":         reason,
            "reportDetail":         detail ?? "",
            "conversationSnapshot": snapshot
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                print("✅ Report submitted for \(character.fullName)")
            }
        } catch {
            print("⚠️ Report submission failed: \(error)")
            // Non-fatal — the user has already tapped submit. Don't surface this error.
        }

        // Clear local session regardless of network outcome.
        // The user should not see this conversation again.
        ChatSessionStore.clearSession(key: sessionKey)

        AnalyticsManager.shared.track(
            event: "character_report_submitted",
            properties: [
                "book_title":     book.title,
                "character_name": character.fullName,
                "report_reason":  reason
            ]
        )
    }

    // MARK: - Helpers

    /// Builds the conversation history array sent to the API.
    /// Only user and character messages — system messages are never sent.
    private func apiHistory() -> [[String: String]] {
        messages
            .filter { $0.role == .user || $0.role == .character }
            .filter { !$0.isStreaming }            // exclude in-flight placeholder
            .map { ["role": $0.role.rawValue, "content": $0.content] }
    }

    // MARK: - Typewriter Engine

    /// Starts draining `typewriterBuffer` character-by-character at a
    /// human typing pace. Runs as a background Task so it doesn't block
    /// the SSE receive loop. Calls `finaliseStream()` when the buffer is
    /// empty AND the network has signalled done.
    @MainActor
    private func startTypewriter() {
        // Runs entirely on MainActor — no actor hopping needed since the whole
        // class is @MainActor. Simple loop: grab a char, update UI, sleep, repeat.
        typewriterTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {

                // Nothing in buffer yet
                guard !self.typewriterBuffer.isEmpty else {
                    if self.networkStreamDone {
                        self.finaliseStream()
                        return
                    }
                    // Network still sending — yield briefly and check again
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    continue
                }

                // Take the next character and display it
                let char = self.typewriterBuffer.removeFirst()
                self.typewriterDisplayed.append(char)
                self.updateStreamingMessage(content: self.typewriterDisplayed, isStreaming: true)

                // Pacing — punctuation creates natural reading rhythm
                let delay: UInt64
                switch char {
                case ".", "!", "?":  delay = 120_000_000  // 120ms — end of sentence
                case ",", ";", ":":  delay =  60_000_000  //  60ms — mid-sentence breath
                case " ":            delay =  18_000_000  //  18ms — word gap
                default:             delay =  28_000_000  //  28ms — base letter speed
                }
                try? await Task.sleep(nanoseconds: delay)
            }
        }
    }

    /// Called by the typewriter when the buffer is drained and the network
    /// has sent `done`. Locks the bubble and persists the session.
    private func finaliseStream() {
        updateStreamingMessage(content: typewriterDisplayed, isStreaming: false)
        streamingMessageId = nil
        isStreaming = false
        typewriterTask = nil
        persistSession()
    }

    /// Updates the content of the current streaming bubble in-place.
    /// SwiftUI re-renders only the changed bubble.
    private func updateStreamingMessage(content: String, isStreaming: Bool) {
        guard let id = streamingMessageId,
              let index = messages.firstIndex(where: { $0.id == id })
        else { return }

        messages[index].content = content
        messages[index].isStreaming = isStreaming
    }

    /// Removes the streaming placeholder if the server returns a terminal
    /// event before any chunks were emitted (safety_block on Tier 1).
    private func removeStreamingPlaceholder() {
        guard let id = streamingMessageId else { return }
        messages.removeAll { $0.id == id }
        streamingMessageId = nil
    }

    /// Surfaces a network/auth error, removes the streaming placeholder,
    /// and resets streaming state. The user sees an error banner; they can retry.
    private func handleNetworkError(_ message: String) {
        removeStreamingPlaceholder()
        isStreaming = false
        error = message
        print("❌ CharacterChat: \(message)")
    }

    /// Persists the current message list to UserDefaults.
    private func persistSession() {
        ChatSessionStore.save(messages: messages, key: sessionKey)
    }


}
