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
    case spanish
    case german

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "Hindi"
        case .marathi: return "Marathi"
        case .spanish: return "Spanish"
        case .german: return "German"
        }
    }
    
    // TTS Voice Code
    var voiceCode: String {
        switch self {
        case .english: return "en-US"
        case .hindi: return "hi-IN"
        case .marathi: return "mr-IN"
        case .spanish: return "es-ES"
        case .german: return "de-DE"
        }
    }
}
