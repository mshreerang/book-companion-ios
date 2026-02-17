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
            let voiceLanguage: String
            switch language {
            case .english:
                voiceLanguage = "en-US"
            case .hindi:
                voiceLanguage = "hi-IN"
            case .marathi:
                voiceLanguage = "hi-IN"
        }
        utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguage)
        // Speech settings
        utterance.rate = 0.5 // Slightly slower for clarity
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // ✅ Add pre-utterance delay for better start
            utterance.preUtteranceDelay = 0.1
        
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }
    
    func resume() {
        synthesizer.continueSpeaking()
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechManager: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
