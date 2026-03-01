import Foundation

enum SummaryLength: String, CaseIterable, Codable, Identifiable {
    case short
    case medium
    
    var id: String { rawValue }
    
    // The name displayed in your UI (e.g., in a Picker or Menu)
    var displayName: String {
        switch self {
        case .short: return "Short"
        case .medium: return "Medium"
        }
    }
    
    // This guidance is sent to the UI to describe what each setting does.
    // It aligns with the logic we put in generate-summary.js
    var promptGuidance: String {
        switch self {
        case .short:
            return "A concise 3-section recap (2-3 paragraphs)."
        case .medium:
            return "A detailed 3-section analysis (4-6 paragraphs)."
        }
    }
}
