//
//  TTSBadgeView.swift
//  BookCompanion
//
//  Project Vani — Phase 3
//
//  Small badge shown inside ActiveNarratorView.
//  Displays: "Narrated in English · nova" (AI) or "Standard Voice" (fallback).
//  All strings use NSLocalizedString.
//

import SwiftUI

// MARK: - TTSBadgeView

struct TTSBadgeView: View {

    let playerState: VaniPlayerState
    let voice: String
    let languageCode: String  // e.g. "en-US", "hi-IN"

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)
                .foregroundColor(foregroundColor)

            Text(badgeText)
                .font(.caption2.weight(.medium))
                .foregroundColor(foregroundColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    // MARK: - Badge Content

    private var badgeText: String {
        switch playerState {
        case .fallback:
            return NSLocalizedString("tts_badge_standard", comment: "Standard voice badge")

        case .prewarming, .downloading:
            return NSLocalizedString("tts_preparing", comment: "Preparing audio badge")

        case .ready, .playing, .paused:
            let langName = localizedLanguageName(for: languageCode)
            let format   = NSLocalizedString("tts_badge_narrated_in", comment: "Narrated in {language} · {voice}")
            // If key not yet in Localizable.strings, format falls back to key name.
            // Use direct interpolation as safety net.
            let resolved = format == "tts_badge_narrated_in"
                ? "Narrated in \(langName) · \(voice)"
                : String(format: format, langName, voice)
            return resolved

        default:
            return ""
        }
    }

    private var iconName: String {
        switch playerState {
        case .fallback:                return "speaker.wave.1.fill"
        case .prewarming, .downloading: return "waveform"
        case .playing:                 return "waveform"
        case .paused, .ready:          return "sparkles"
        default:                       return "sparkles"
        }
    }

    private var foregroundColor: Color {
        switch playerState {
        case .fallback:    return .secondary
        case .downloading: return .secondary
        default:           return .accentColor
        }
    }

    private var backgroundColor: Color {
        switch playerState {
        case .fallback:    return Color(.systemGray5)
        case .downloading: return Color(.systemGray5)
        default:           return Color.accentColor.opacity(0.12)
        }
    }

    // MARK: - Language Name

    /// Returns a human-readable language name from a BCP-47 code.
    /// Uses the device locale so it reads naturally in the user's language.
    private func localizedLanguageName(for code: String) -> String {
        // Strip region for lookup: "en-US" → "en", "hi-IN" → "hi"
        let langCode = code.components(separatedBy: "-").first ?? code
        return Locale.current.localizedString(forLanguageCode: langCode)
            ?? langCode.uppercased()
    }
}

// MARK: - Preview

#if DEBUG
struct TTSBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            TTSBadgeView(playerState: .ready,    voice: "nova",   languageCode: "en-US")
            TTSBadgeView(playerState: .playing,  voice: "shimmer", languageCode: "hi-IN")
            TTSBadgeView(playerState: .fallback, voice: "nova",   languageCode: "en-US")
            TTSBadgeView(playerState: .downloading(0.4), voice: "nova", languageCode: "en-US")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
