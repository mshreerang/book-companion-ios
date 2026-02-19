//
//  TextToSpeechManager.swift
//  BookCompanion
//
//  Created by Shree on 07/02/2026.
//

import AVFoundation
import Combine

final class TextToSpeechManager: NSObject, ObservableObject {
    
    static let shared = TextToSpeechManager()
    
    @Published var isSpeaking = false
    @Published var isPaused = false  // ✅ NEW: Track pause state
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(text: String, language: Language) {
        guard !text.isEmpty else { return }
        
        // Stop if already speaking
        if isSpeaking {
            stop()
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Set voice based on language
        switch language {
        case .english:
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        case .hindi:
            utterance.voice = AVSpeechSynthesisVoice(language: "hi-IN")
        case .marathi:
            utterance.voice = AVSpeechSynthesisVoice(language: "mr-IN")
        }
        
        // Speech settings
        utterance.rate = 0.5 // Slightly slower for clarity
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        isSpeaking = true
        isPaused = false  // ✅ NEW: Reset pause state
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false  // ✅ NEW: Reset pause state
    }
    
    func pause() {
        synthesizer.pauseSpeaking(at: .word)
        isPaused = true  // ✅ NEW: Set pause state
    }
    
    func resume() {
        synthesizer.continueSpeaking()
        isPaused = false  // ✅ NEW: Clear pause state
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechManager: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false  // ✅ NEW: Clear pause state when done
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false  // ✅ NEW: Clear pause state when cancelled
    }
    
    // ✅ NEW: Track pause events
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        isPaused = true
    }
    
    // ✅ NEW: Track resume events
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        isPaused = false
    }
}
