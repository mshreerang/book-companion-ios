//
//  TextToSpeechManager.swift
//  BookCompanion
//
//  Created by Shree on 07/02/2026.
//

import AVFoundation
import Combine

// MARK: - TextToSpeechManager

/// Coordinator that owns whichever TTSEngine is active.
/// SummaryView calls this exactly as before — no changes needed at call sites.
///
/// To add AI narration (ElevenLabs / OpenAI TTS):
///   1. Create AITTSEngine: TTSEngine
///   2. Call TextToSpeechManager.shared.switchEngine(to: .ai)
///   That's it — no view code changes required.
final class TextToSpeechManager: ObservableObject {

    // MARK: - Singleton

    static let shared = TextToSpeechManager()

    // MARK: - Published State (mirrors active engine)

    @Published var isSpeaking = false
    @Published var isPaused = false

    // MARK: - Engine

    private(set) var activeEngineType: TTSEngineType = .system
    private var engine: TTSEngine
    private var engineCancellables = Set<AnyCancellable>()

    // MARK: - Init

    private init() {
        engine = AVSpeechEngine()
        observeEngine()
    }

    // MARK: - Public API (unchanged from original — SummaryView needs no edits)

    func speak(text: String, language: Language) {
        engine.speak(text: text, language: language)
    }

    func stop() {
        engine.stop()
    }

    func pause() {
        engine.pause()
    }

    func resume() {
        engine.resume()
    }

    // MARK: - Engine Switching
    //
    // Call this when AI narration is ready, e.g. from a settings toggle:
    //
    //   TextToSpeechManager.shared.switchEngine(to: .ai)
    //
    // The engine swap happens mid-session safely — any active speech is
    // stopped before switching.

    func switchEngine(to type: TTSEngineType) {
        guard type != activeEngineType else { return }

        // Stop current engine cleanly before swapping
        if engine.isSpeaking { engine.stop() }

        engineCancellables.removeAll()

        switch type {
        case .system:
            engine = AVSpeechEngine()
        case .ai:
            // Replace this with AITTSEngine() when ready:
            // engine = AITTSEngine(apiKey: Config.elevenLabsKey)
            print("⚠️ AI TTS engine not yet implemented — staying on system engine")
            return
        }

        activeEngineType = type
        observeEngine()

        print("✅ TTS engine switched to: \(type)")
    }

    // MARK: - Private

    /// Forward engine's published state to our @Published properties
    /// so SwiftUI views observing TextToSpeechManager keep working.
    private func observeEngine() {
        engine.isSpeakingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSpeaking, on: self)
            .store(in: &engineCancellables)

        engine.isPausedPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPaused, on: self)
            .store(in: &engineCancellables)
    }
}
