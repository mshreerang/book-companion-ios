//
//  OpenAISummaryGenerator.swift
//  BookCompanion
//
//  Created by Shree on 04/02/2026.
//

import Foundation

final class OpenAISummaryGenerator: SummaryGenerator {

    // MARK: - Configuration

    private let apiKey: String
    private let model = "gpt-4o-mini"
    private let endpoint = "https://api.openai.com/v1/chat/completions"

    // MARK: - Init

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - SummaryGenerator

    func generateSummary(
        book: Book,
        chapter: Int,
        language: Language,
        length: SummaryLength
    ) async throws -> BookSummary {

        let prompt = """
        You are a careful reading companion.

        Summarise the story of the book titled "\(book.title)" by \(book.author)
        up to and including chapter \(chapter).

        Rules:
        - Write the summary in \(language.displayName).
        - Do NOT include spoilers or events beyond chapter \(chapter).
        - Focus on major plot developments and character arcs.
        - Do not invent details not supported by the text.
        - Do not mention future events or speculate.
        - \(length.promptGuidance)

        Output only the summary text.
        """

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.3
        ]

        let data = try await sendRequest(body: requestBody)
        let content = try parseSummary(from: data)

        return BookSummary(
            id: UUID(),
            bookId: book.id,
            chapter: chapter,
            progressId: UUID(),
            content: content,
            language: language,
            length: length,
            generatedAt: Date()
        )
    }

    func generateCharacters(
        book: Book,
        chapter: Int,
        language: Language
    ) async throws -> [BookCharacter] {
        
        let prompt = """
        You are a careful reading companion.

        List the main characters introduced in the book titled "\(book.title)" by \(book.author)
        up to and including chapter \(chapter).

        Rules:
        - Write in \(language.displayName).
        - Only include characters that have appeared up to chapter \(chapter).
        - Do NOT include characters or plot points beyond chapter \(chapter).
        - For each character, provide:
          * Name
          * A brief one-line description of who they are
          * Key relationships (optional)

        Format your response as a JSON array:
        [
          {
            "name": "Character Name",
            "description": "Brief description",
            "relationships": "Key relationships or null"
          }
        ]

        Output only valid JSON.
        """

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.3,
            "response_format": ["type": "json_object"]
        ]

        let data = try await sendRequest(body: requestBody)
        let characters = try parseCharacters(from: data, bookId: book.id, language: language)
        
        return characters
    }

    // MARK: - Networking

    private func sendRequest(body: [String: Any]) async throws -> Data {

        guard let url = URL(string: endpoint) else {
            throw AIError.requestFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.requestFailed
        }
        
        // ✅ Fixed: Proper switch statement
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw AIError.unauthorized
        case 429:
            throw AIError.rateLimited
        default:
            throw AIError.requestFailed
        }
    }

    // MARK: - Parsing

    private func parseSummary(from data: Data) throws -> String {

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard
            let choices = json?["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw AIError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseCharacters(
        from data: Data,
        bookId: UUID,
        language: Language
    ) throws -> [BookCharacter] {
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard
            let choices = json?["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String,
            let contentData = content.data(using: .utf8)
        else {
            throw AIError.invalidResponse
        }
        
        // Parse the JSON array from the content
        guard let charactersArray = try JSONSerialization.jsonObject(with: contentData) as? [[String: Any]] else {
            throw AIError.invalidResponse
        }
        
        return charactersArray.compactMap { dict in
            guard
                let name = dict["name"] as? String,
                let description = dict["description"] as? String
            else {
                return nil
            }
            
            let relationships = dict["relationships"] as? String
            
            return BookCharacter(
                id: UUID(),
                bookId: bookId,
                progressId: UUID(),
                name: name,
                description: description,
                relationships: relationships,
                language: language,
                generatedAt: Date()
            )
        }
    }
}

// MARK: - Errors

enum AIError: LocalizedError {
    case requestFailed
    case invalidResponse
    case networkError(Error)
    case unauthorized
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .requestFailed:
            return "Failed to connect to AI service. Check your internet connection."
        case .invalidResponse:
            return "Received invalid response from AI service."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Invalid API key. Please check your settings."
        case .rateLimited:
            return "Rate limit exceeded. Please try again in a moment."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unauthorized:
            return "Go to Settings and verify your API key is correct."
        case .networkError, .requestFailed:
            return "Check your internet connection and try again, or switch to Offline mode in Settings."
        case .rateLimited:
            return "Wait a moment before trying again."
        case .invalidResponse:
            return "Try regenerating the summary."
        }
    }
}
