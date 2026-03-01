import Foundation

// Model for character card with two-name strategy
struct CharacterCard: Identifiable, Codable {
    let id: String          // Input name (for state management)
    let fullName: String    // Canonical name (for display)
    
    // Optional - loaded on demand
    var description: String?
    var relationships: String?
    var currentSituation: String?
    var role: String?

    // Loaded with getDetails — shown as suggested chips in CharacterChatView.
    // nil on cards loaded via prewarm (fast path); non-nil after full detail fetch.
    // Codable handles this automatically because it's optional — no CodingKeys needed.
    var suggestedQuestions: [String]?

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
