//
//  ServerAISummaryGenerator.swift
//  BookCompanion
//
//  Created by Shree on 06/02/2026.
//

import Foundation
import Combine

final class ServerAISummaryGenerator: SummaryGenerator {
    
    // MARK: - Properties
    
    private let endpoint: String
    private let appSecret: String
    private let session: URLSession
    
    // MARK: - Initialization
    
    init(endpoint: String, appSecret: String) {
        self.endpoint = endpoint
        self.appSecret = appSecret
        
        // Configure session with timeout
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Config.summaryTimeoutSeconds
        configuration.timeoutIntervalForResource = Config.summaryTimeoutSeconds
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - SummaryGenerator Protocol
    
    func generateSummary(
        book: Book,
        chapter: Int,
        language: Language,
        length: SummaryLength
    ) async throws -> BookSummary {
        
        let url = try makeURL(path: "/api/generate-summary")
        var request = makeRequest(url: url)
        
        // Build request body
        let requestBody: [String: Any] = [
            "bookTitle": book.title,
            "author": book.author,
            "chapter": chapter,
            "language": language.displayName,
            "length": length.rawValue
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make request
        let (data, response) = try await session.data(for: request)
        
        // Handle response
        try validateResponse(response)
        
        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let success = json?["success"] as? Bool, success,
              let summary = json?["summary"] as? String else {
            
            // Check for error message from server
            if let error = json?["error"] as? String {
                throw mapServerError(error)
            }
            
            throw AIError.invalidResponse
        }
        
        // Log for debugging
        #if DEBUG
        if let tokensUsed = json?["tokensUsed"] as? Int {
            print("✓ Summary generated. Tokens used: \(tokensUsed)")
        }
        #endif
        
        return BookSummary(
            id: UUID(),
            bookId: book.id,
            chapter: chapter,
            progressId: UUID(),
            content: summary,
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
        
        let url = try makeURL(path: "/api/generate-characters")
        var request = makeRequest(url: url)
        
        // Build request body
        let requestBody: [String: Any] = [
            "bookTitle": book.title,
            "author": book.author,
            "chapter": chapter,
            "language": language.displayName
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make request
        let (data, response) = try await session.data(for: request)
        
        // Handle response
        try validateResponse(response)
        
        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let success = json?["success"] as? Bool, success,
              let charactersArray = json?["characters"] as? [[String: Any]] else {
            
            if let error = json?["error"] as? String {
                throw mapServerError(error)
            }
            
            throw AIError.invalidResponse
        }
        
        // Log for debugging
        #if DEBUG
        print("✓ Characters generated. Count: \(charactersArray.count)")
        if let tokensUsed = json?["tokensUsed"] as? Int {
            print("  Tokens used: \(tokensUsed)")
        }
        #endif
        
        // Convert to BookCharacter objects
        return charactersArray.compactMap { dict in
            guard let name = dict["name"] as? String,
                  let description = dict["description"] as? String else {
                return nil
            }
            
            let relationships = dict["relationships"] as? String
            
            return BookCharacter(
                id: UUID(),
                bookId: book.id,
                progressId: UUID(),
                name: name,
                description: description,
                relationships: relationships,
                language: language,
                generatedAt: Date()
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func makeURL(path: String) throws -> URL {
        guard let url = URL(string: endpoint + path) else {
            throw AIError.requestFailed
        }
        return url
    }
    
    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(appSecret, forHTTPHeaderField: "X-App-Secret")

        // Auth: JWT for signed-in users, device hash for guests
        if GuestManager.shared.isGuestMode {
            request.addValue(GuestManager.shared.deviceHash, forHTTPHeaderField: "X-Device-Hash")
        } else if let userToken = KeychainManager.shared.getUserToken() {
            request.addValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        }

        return request
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.requestFailed
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
            
        case 401:
            throw AIError.unauthorized
            
        case 429:
            throw AIError.rateLimited
            
        case 400:
            throw AIError.invalidResponse
            
        case 500...599:
            throw AIError.requestFailed
            
        default:
            throw AIError.requestFailed
        }
    }
    
    private func mapServerError(_ error: String) -> AIError {
        switch error.lowercased() {
        case let e where e.contains("unauthorized"):
            return .unauthorized
        case let e where e.contains("rate limit"):
            return .rateLimited
        case let e where e.contains("invalid"):
            return .invalidResponse
        default:
            return .requestFailed
        }
    }
}
