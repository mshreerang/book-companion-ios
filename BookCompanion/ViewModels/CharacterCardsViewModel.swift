import Foundation
import SwiftUI
import Combine

@MainActor
class CharacterCardsViewModel: ObservableObject {
    @Published var names: [String] = []
    @Published var detailsCache: [String: CharacterCard] = [:]
    @Published var isLoadingNames = false
    @Published var error: String?
    
    private let book: Book
    private let chapter: Int
    private let language: String
    private let allBooks: [Book]   // for series context injection
    
    init(book: Book, chapter: Int, language: String = "English", allBooks: [Book] = []) {
        self.book = book
        self.chapter = chapter
        self.language = language
        self.allBooks = allBooks
    }
    
    // MARK: - Series Context Helper

    /// Build series context dict for API requests.
    /// Returns nil for standalone books — no overhead.
    private func buildSeriesContextDict() -> [String: Any]? {
        guard let ctx = SeriesManager.shared.buildAIContext(for: book, allBooks: allBooks),
              let encoded = try? JSONEncoder().encode(ctx),
              let dict = try? JSONSerialization.jsonObject(with: encoded) as? [String: Any] else {
            return nil
        }
        print("📚 Series context injected for characters: \(ctx.seriesName) Book \(ctx.bookPosition)")
        return dict
    }

    // MARK: - Load Names (Fast!)
    
    func loadNames() async {
        isLoadingNames = true
        error = nil
        
        do {
            // Step 1: Fetch names
            let response = try await fetchCharacterNames()
            self.names = response.names
            
            // Step 2: Pre-warm top 2 characters (background)
            if response.names.count >= 2 {
                Task {
                    await prewarmTopCharacters(Array(response.names.prefix(2)))
                }
            }
            
            isLoadingNames = false
        } catch {
            self.error = error.localizedDescription
            isLoadingNames = false
            print("❌ Error loading character names: \(error)")
        }
    }
    
    // MARK: - Load Details (On Demand)
    
    /// Returns (character, isQuotaError).
    /// isQuotaError=true means the user has hit their monthly analysis limit.
    func loadDetails(for name: String) async -> (CharacterCard?, Bool) {
        // ✅ Check cache first
        if let cached = detailsCache[name] {
            print("✅ Using cached details for \(name)")
            return (cached, false)
        }
        
        // Fetch on demand
        do {
            let response = try await fetchCharacterDetails(for: name)
            let character = response.character
            
            print("✅ Fetched character: \(character.fullName)")
            print("   Description: \(character.description ?? "nil")")
            
            // ✅ Update cache IMMEDIATELY
            await MainActor.run {
                self.detailsCache[name] = character
            }
            
            return (character, false)
            
        } catch CharacterAPIError.quotaExceeded(let message) {
            print("❌ Quota exceeded for \(name): \(message)")
            return (nil, true)
        } catch {
            print("❌ Error loading details for \(name): \(error)")
            return (nil, false)
        }
    }
    
    // MARK: - Pre-Warm Strategy
    
    private func prewarmTopCharacters(_ names: [String]) async {
        do {
            let response = try await prewarmCharacters(names)
            
            // Cache all pre-warmed characters
            for character in response.characters {
                detailsCache[character.id] = character
            }
            
            print("🔥 Pre-warmed \(response.characters.count) characters")
            
        } catch {
            print("⚠️ Pre-warm failed: \(error)")
            // Not critical - characters will load on demand
        }
    }
    
    // MARK: - API Calls
    
    private func fetchCharacterNames() async throws -> CharacterNamesResponse {
        let url = URL(string: "\(Config.apiEndpoint)/api/characters")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let userToken = KeychainManager.shared.getUserToken() else {
            throw CharacterAPIError.unauthorized
        }
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [
            "action": "getNames",
            "bookTitle": book.title,
            "author": book.author,
            "chapter": chapter,
            "language": language
        ]
        if let ctx = buildSeriesContextDict() { body["seriesContext"] = ctx }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // ✅ Check HTTP response
        try checkHTTPResponse(response, data: data)
        
        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let success = json?["success"] as? Bool, success,
              let characters = json?["characters"] as? [String],
              let tokensUsed = json?["tokensUsed"] as? Int else {
            throw CharacterAPIError.invalidResponse
        }
        
        return CharacterNamesResponse(
            success: success,
            names: characters,
            tokensUsed: tokensUsed,
            cached: false
        )
    }
    
    private func fetchCharacterDetails(for name: String) async throws -> CharacterDetailsResponse {
        let url = URL(string: "\(Config.apiEndpoint)/api/characters")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let userToken = KeychainManager.shared.getUserToken() else {
            throw CharacterAPIError.unauthorized
        }
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [
            "action": "getDetails",
            "bookTitle": book.title,
            "author": book.author,
            "chapter": chapter,
            "characterName": name,
            "language": language
        ]
        if let ctx = buildSeriesContextDict() { body["seriesContext"] = ctx }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // ✅ Check HTTP response
        try checkHTTPResponse(response, data: data)
        
        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let success = json?["success"] as? Bool, success,
              let description = json?["description"] as? String,
              let tokensUsed = json?["tokensUsed"] as? Int else {
            throw CharacterAPIError.invalidResponse
        }
        
        let character = CharacterCard(
            id: name,
            fullName: name,
            description: description,
            relationships: nil,
            currentSituation: nil,
            role: nil
            
        )
        
        return CharacterDetailsResponse(
            success: success,
            character: character,
            tokensUsed: tokensUsed,
            cached: false
        )
    }
    
    private func prewarmCharacters(_ names: [String]) async throws -> PrewarmCharactersResponse {
        let url = URL(string: "\(Config.apiEndpoint)/api/characters")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let userToken = KeychainManager.shared.getUserToken() else {
            throw CharacterAPIError.unauthorized
        }
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [
            "action": "prewarm",
            "bookTitle": book.title,
            "author": book.author,
            "chapter": chapter,
            "characterNames": names,
            "language": language
        ]
        if let ctx = buildSeriesContextDict() { body["seriesContext"] = ctx }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // ✅ Check HTTP response
        try checkHTTPResponse(response, data: data)
        
        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let success = json?["success"] as? Bool, success,
              let charactersArray = json?["characters"] as? [[String: Any]],
              let tokensUsed = json?["tokensUsed"] as? Int else {
            throw CharacterAPIError.invalidResponse
        }
        
        let characters = charactersArray.compactMap { dict -> CharacterCard? in
            guard let name = dict["name"] as? String,
                  let description = dict["description"] as? String else {
                return nil
            }
            
            return CharacterCard(
                id: name,
                fullName: name,
                description: description,
                relationships: nil,
                currentSituation: nil,
                role: nil
            )
        }
        
        return PrewarmCharactersResponse(
            success: success,
            characters: characters,
            tokensUsed: tokensUsed,
            cached: false
        )
    }
    
    // MARK: - Helper Methods
    
    /// ✅ DRY: Centralized HTTP response checking
    private func checkHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CharacterAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return // Success
            
        case 429:
            // Quota exceeded - parse the error message from backend
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                throw CharacterAPIError.quotaExceeded(message)
            }
            throw CharacterAPIError.quotaExceeded("Character limit reached. Upgrade to Pro for unlimited!")
            
        case 401:
            throw CharacterAPIError.unauthorized
            
        default:
            throw CharacterAPIError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - Error Types

enum CharacterAPIError: LocalizedError {
    case unauthorized
    case quotaExceeded(String)
    case serverError(statusCode: Int)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in to view characters"
        case .quotaExceeded(let message):
            return message
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}
