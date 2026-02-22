import Foundation
import SwiftUI

@MainActor
class CharacterCardsViewModel: ObservableObject {
    @Published var names: [String] = []
    @Published var detailsCache: [String: CharacterCard] = [:]
    @Published var isLoadingNames = false
    @Published var error: String?
    
    private let generator: CharacterGenerator
    private let book: Book
    private let chapter: Int
    private let language: String
    
    init(book: Book, chapter: Int, language: String = "English") {
        self.book = book
        self.chapter = chapter
        self.language = language
        self.generator = CharacterGenerator()
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
        }
    }
    
    // MARK: - Load Details (On Demand)
    
    func loadDetails(for name: String) async -> CharacterCard? {
        // ✅ IMPROVEMENT #3: Check cache first (critical!)
        if let cached = detailsCache[name] {
            print("✅ Using cached details for \(name)")
            return cached
        }
        
        // Fetch on demand
        do {
            let response = try await fetchCharacterDetails(for: name)
            let character = response.character
            
            // ✅ CRITICAL: Update cache IMMEDIATELY to prevent duplicate calls
            await MainActor.run {
                self.detailsCache[name] = character
            }
            
            print("✅ Fetched and cached details for \(name)")
            return character
            
        } catch {
            print("❌ Error loading details for \(name): \(error)")
            return nil
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
        let url = URL(string: "\(Config.apiEndpoint)/api/get-character-names")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.appSecret, forHTTPHeaderField: "X-App-Secret")
        
        let body: [String: Any] = [
            "bookTitle": book.title,
            "author": book.author,
            "chapter": chapter,
            "language": language
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(CharacterNamesResponse.self, from: data)
    }
    
    private func fetchCharacterDetails(for name: String) async throws -> CharacterDetailsResponse {
        let url = URL(string: "\(Config.apiEndpoint)/api/get-character-details")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.appSecret, forHTTPHeaderField: "X-App-Secret")
        
        let body: [String: Any] = [
            "bookTitle": book.title,
            "author": book.author,
            "chapter": chapter,
            "characterName": name,
            "language": language
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(CharacterDetailsResponse.self, from: data)
    }
    
    private func prewarmCharacters(_ names: [String]) async throws -> PrewarmCharactersResponse {
        let url = URL(string: "\(Config.apiEndpoint)/api/prewarm-characters")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.appSecret, forHTTPHeaderField: "X-App-Secret")
        
        let body: [String: Any] = [
            "bookTitle": book.title,
            "author": book.author,
            "chapter": chapter,
            "topCharacters": names,
            "language": language
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(PrewarmCharactersResponse.self, from: data)
    }
}
