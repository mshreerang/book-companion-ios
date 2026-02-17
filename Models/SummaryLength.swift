//
//  SummaryLength.swift
//  BookCompanion
//
//  Created by Shree on 04/02/2026.
//

import Foundation

enum SummaryLength: String, CaseIterable, Codable, Identifiable {
    case short
    case medium
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .short: return "Short"
        case .medium: return "Medium"
        }
    }
    
    var promptGuidance: String {
        switch self {
        case .short:
            return "Keep it brief - 2-3 paragraphs maximum."
        case .medium:
            return "Provide a comprehensive summary - 4-6 paragraphs."
        }
    }
}
