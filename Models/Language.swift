//
//  Language.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
import Foundation

enum Language: String, CaseIterable, Identifiable, Codable {
    case english
    case hindi
    case marathi

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "Hindi"
        case .marathi: return "Marathi"
        }
    }
    
    // ✅ ADD THIS - TTS Voice Code
    var voiceCode: String {
        switch self {
        case .english: return "en-US"
        case .hindi: return "hi-IN"
        case .marathi: return "hi-IN"  // Fallback to Hindi (same Devanagari script)
        }
    }
}
