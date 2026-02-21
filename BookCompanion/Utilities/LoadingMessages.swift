//
//  LoadingMessages.swift
//  BookCompanion
//
//  Created by Shree on 19/02/2026.
//

import Foundation

enum LoadingMessages {
    
    static let summaryMessages = [
        "📖 Reading through the chapters...",
        "💭 Analyzing the plot twists...",
        "✨ Capturing the key moments...",
        "🔍 Finding the important details...",
        "📚 Piecing together the story...",
        "🎭 Understanding character arcs...",
        "💡 Connecting the narrative threads...",
        "🌟 Summarizing the journey...",
        "📝 Crafting your summary...",
        "🎬 Recapping the story so far...",
        "🧩 Organizing the plot points...",
        "⚡ Processing the chapters...",
        "🎨 Painting the story picture...",
        "🔮 Revealing what happened...",
        "📜 Writing your recap..."
    ]
    
    static let charactersMessages = [
        "👥 Finding the characters...",
        "🎭 Analyzing relationships...",
        "💬 Discovering character traits...",
        "🌟 Meeting the cast...",
        "📝 Listing the key players...",
        "🎪 Gathering the ensemble...",
        "✨ Learning about the characters..."
    ]
    static func randomCharacterMessage() -> String {
        let messages = [
            "👥 Meeting the characters...",
            "📝 Noting character relationships...",
            "🎭 Analyzing character development...",
            "💭 Understanding character motivations...",
            "🔍 Identifying key players...",
            "✨ Mapping character connections...",
            "📖 Profiling story participants..."
        ]
        return messages.randomElement() ?? "Loading characters..."
    }
    
    static func randomSummaryMessage() -> String {
        summaryMessages.randomElement() ?? "Loading..."
    }
    
    static func randomCharactersMessage() -> String {
        charactersMessages.randomElement() ?? "Loading..."
    }
}
