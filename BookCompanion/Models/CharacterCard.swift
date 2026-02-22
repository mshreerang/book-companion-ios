import Foundation

// Model for character card with two-name strategy
struct CharacterCard: Identifiable, Codable {
    let id: String          // Input name (for state management)
    let fullName: String    // Canonical name (for display)
    
    // Optional - loaded on demand
    var description: String?
    var relationships: String?
    var currentSituation: String?
    
    // Computed property for display name
    var displayName: String {
        fullName
    }
}

// Response from get-character-names
struct CharacterNamesResponse: Codable {
    let success: Bool
    let names: [String]
    let tokensUsed: Int
    let cached: Bool
}

// Response from get-character-details
struct CharacterDetailsResponse: Codable {
    let success: Bool
    let character: CharacterCard
    let tokensUsed: Int
    let cached: Bool
}

// Response from prewarm-characters
struct PrewarmCharactersResponse: Codable {
    let success: Bool
    let characters: [CharacterCard]
    let tokensUsed: Int
    let cached: Bool
}
