//
//  AVSpeechEngine.swift
//  BookCompanion
//
//  Created by Shree on 27/02/2026.
//

import AVFoundation
import Combine

// MARK: - AVSpeechEngine

/// Concrete TTSEngine backed by iOS AVSpeechSynthesizer.
/// Handles voice availability at runtime — if a language voice isn't
/// installed on the device it falls back gracefully rather than silently failing.
final class AVSpeechEngine: NSObject, TTSEngine {

    // MARK: - Published State

    @Published private var _isSpeaking = false
    @Published private var _isPaused = false

    var isSpeaking: Bool { _isSpeaking }
    var isPaused: Bool { _isPaused }

    var isSpeakingPublisher: AnyPublisher<Bool, Never> {
        $_isSpeaking.eraseToAnyPublisher()
    }
    var isPausedPublisher: AnyPublisher<Bool, Never> {
        $_isPaused.eraseToAnyPublisher()
    }

    // MARK: - Private

    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - Init

    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    // MARK: - TTSEngine

    func speak(text: String, language: Language) {
        guard !text.isEmpty else { return }

        if _isSpeaking { stop() }

        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = resolveVoice(for: language)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        _isSpeaking = true
        _isPaused = false
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        _isSpeaking = false
        _isPaused = false
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
        _isPaused = true
    }

    func resume() {
        synthesizer.continueSpeaking()
        _isPaused = false
    }

    // MARK: - Voice Resolution

    /// Resolves the best available voice for a language at runtime.
    /// Falls back gracefully if the preferred voice isn't installed on the device.
    private func resolveVoice(for language: Language) -> AVSpeechSynthesisVoice? {
        switch language {

        case .english:
            return AVSpeechSynthesisVoice(language: "en-US")

        case .spanish:
            return AVSpeechSynthesisVoice(language: "es-ES")

        case .german:
            return AVSpeechSynthesisVoice(language: "de-DE")

        case .hindi:
            return AVSpeechSynthesisVoice(language: "hi-IN")

        case .marathi:
            // Apple doesn't ship an mr-IN voice on most devices (as of iOS 17).
            // Try mr-IN first — this will work automatically if Apple adds it in a
            // future iOS release without any code change needed.
            // Falls back to hi-IN (same Devanagari script, mutually intelligible for TTS).
            return AVSpeechSynthesisVoice(language: "mr-IN")
                ?? AVSpeechSynthesisVoice(language: "hi-IN")
        }
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true)
        } catch {
            print("❌ AVSpeechEngine: Failed to configure audio session: \(error)")
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension AVSpeechEngine: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        _isSpeaking = false
        _isPaused = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        _isSpeaking = false
        _isPaused = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        _isPaused = true
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        _isPaused = false
    }
}
