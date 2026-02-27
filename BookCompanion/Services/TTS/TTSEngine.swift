//
//  TTSEngine.swift
//  BookCompanion
//
//  Created by Shree on 27/02/2026.
//

import Foundation
import Combine

// MARK: - Protocol

/// Abstraction over any TTS backend (AVSpeech, ElevenLabs, OpenAI TTS, etc.)
/// SummaryView and any other consumer only ever talks to this protocol,
/// so swapping in AI narration is a one-file change.
protocol TTSEngine: AnyObject {

    var isSpeaking: Bool { get }
    var isPaused: Bool { get }

    /// Published so SwiftUI views can observe state changes
    var isSpeakingPublisher: AnyPublisher<Bool, Never> { get }
    var isPausedPublisher: AnyPublisher<Bool, Never> { get }

    func speak(text: String, language: Language)
    func stop()
    func pause()
    func resume()
}

// MARK: - Engine Type

/// Which engine is currently active.
/// Extend this when AI narration is ready.
enum TTSEngineType {
    case system          // AVSpeech — always available, free
    case ai              // ElevenLabs / OpenAI TTS — future
}
