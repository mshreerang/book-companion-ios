//
//  ActiveNarratorView.swift
//  BookCompanion
//
//  Project Vani — Phase 3 (Redesigned for discoverability)
//
//  MINI PLAYER (~76pt tall, always visible):
//  ┌─────────────────────────────────────────────┐
//  │▌ 〰〰〰〰  Story So Far · Ch.8   ⏸   ∧  ✕ │
//  │▌         ▶ AI Narration · nova              │
//  └─────────────────────────────────────────────┘
//  Accent left border + waveform + chevron hint
//
//  EXPANDED (.medium / .large sheet):
//  Full waveform + seek bar + speed + skip controls
//

import SwiftUI
import AVFoundation

// MARK: - ActiveNarratorView

struct ActiveNarratorView: View {

    @ObservedObject var viewModel: VaniPlayerViewModel

    let fallbackText: String
    let fallbackLanguage: Language
    let chapterTitle: String
    var onPrewarmTap: (() -> Void)? = nil
    var isSummaryReady: Bool = false  // false while summary is still generating

    @State private var showExpanded = false
    @State private var pulseExpand  = false   // subtle pulse to hint at tap
    @State private var miniLevels: [CGFloat] = [0.4, 0.7, 0.5, 0.8, 0.4]
    @State private var miniTimer: Timer? = nil
    @State private var miniPhase: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            switch viewModel.playerState {

            case .idle:
                miniIdleBar

            case .prewarming, .downloading:
                miniLoadingBar

            case .ready, .playing, .paused:
                miniPlayer
                    .onTapGesture { showExpanded = true }

            case .fallback:
                miniFallbackBar
            }
        }
        .sheet(isPresented: $showExpanded) {
            expandedPlayer
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
        .onChange(of: viewModel.playerState) {
            handleStateChange(viewModel.playerState)
        }
    }

    // MARK: - Mini Player (playing / paused / ready)

    private var miniPlayer: some View {
        HStack(spacing: 0) {

            // ── Accent left border ────────────────────────────────────────
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.accentColor)
                .frame(width: 3)
                .padding(.vertical, 10)
                .padding(.leading, 12)

            // ── Waveform bars ─────────────────────────────────────────────
            miniWaveformIcon
                .padding(.leading, 10)

            // ── Title + subtitle ──────────────────────────────────────────
            VStack(alignment: .leading, spacing: 3) {
                Text(chapterTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(voiceSubtitle)
                    .font(.caption2)
                    .foregroundColor(.accentColor)
                    .lineLimit(1)
            }
            .padding(.leading, 10)

            Spacer()

            // ── Play / Pause ──────────────────────────────────────────────
            Button {
                viewModel.togglePlayPause()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: playPauseIcon)
                    .font(.title3.weight(.semibold))
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(viewModel.playerState == .playing
                ? NSLocalizedString("tts_pause", comment: "")
                : NSLocalizedString("tts_play", comment: ""))

            // ── Expand chevron ────────────────────────────────────────────
            Image(systemName: "chevron.up")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
                .frame(width: 20)
                .scaleEffect(pulseExpand ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 0.9).repeatCount(3, autoreverses: true),
                           value: pulseExpand)

            // ── Dismiss ───────────────────────────────────────────────────
            Button {
                viewModel.reset()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Dismiss player")
            .padding(.trailing, 12)
            .padding(.leading, 4)
        }
        .frame(height: 72)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 1)
                )
        }
        .shadow(color: Color.accentColor.opacity(0.15), radius: 14, x: 0, y: 4)
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
        .onAppear {
            // Pulse chevron once on first appear to hint at expand
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                pulseExpand = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    pulseExpand = false
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint("Double-tap to open full player")
    }

    // MARK: - Mini Idle Bar

    private var miniIdleBar: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.accentColor.opacity(isSummaryReady ? 0.8 : 0.3))
                .frame(width: 3)
                .padding(.vertical, 10)
                .padding(.leading, 12)

            Image(systemName: isSummaryReady ? "sparkles" : "ellipsis")
                .font(.subheadline)
                .foregroundColor(isSummaryReady ? .accentColor : .secondary)
                .padding(.leading, 12)
                .symbolEffect(.variableColor.iterative, isActive: !isSummaryReady)

            VStack(alignment: .leading, spacing: 3) {
                Text(isSummaryReady ? "AI Narration Available" : "AI Narration")
                    .font(.subheadline.weight(.semibold))
                Text(isSummaryReady ? "Tap to listen to this summary" : "Ready after summary loads")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 10)

            Spacer()

            if isSummaryReady {
                Image(systemName: "play.fill")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .padding(.trailing, 16)
            }
        }
        .frame(height: 72)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.accentColor.opacity(isSummaryReady ? 0.2 : 0.1), lineWidth: 1)
                )
        }
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .onTapGesture {
            guard isSummaryReady else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onPrewarmTap?()
        }
    }

    // MARK: - Mini Loading Bar

    private var miniLoadingBar: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.accentColor.opacity(0.5))
                .frame(width: 3)
                .padding(.vertical, 10)
                .padding(.leading, 12)

            // Animated waveform shimmer while loading
            HStack(alignment: .center, spacing: 2) {
                ForEach(Array([8.0, 14.0, 10.0, 16.0, 8.0].enumerated()), id: \.offset) { idx, h in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.accentColor.opacity(0.4))
                        .frame(width: 3, height: h)
                        .animation(
                            .easeInOut(duration: 0.5 + Double(idx) * 0.08)
                                .repeatForever(autoreverses: true),
                            value: idx
                        )
                }
            }
            .frame(width: 28, height: 22)
            .padding(.leading, 10)

            VStack(alignment: .leading, spacing: 3) {
                Text(loadingTitle)
                    .font(.subheadline.weight(.semibold))
                if case .downloading(let p) = viewModel.playerState, p > 0 {
                    Text("Generating audio…")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("This takes about 30 seconds")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 10)

            Spacer()

            if case .downloading(let p) = viewModel.playerState, p > 0 {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 2.5)
                        .frame(width: 32, height: 32)
                    Circle()
                        .trim(from: 0, to: CGFloat(p))
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: p)
                    Text("\(Int(p * 100))")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                }
                .padding(.trailing, 14)
            } else {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.accentColor)
                    .padding(.trailing, 16)
            }
        }
        .frame(height: 72)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.accentColor.opacity(0.15), lineWidth: 1)
                )
        }
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    // MARK: - Mini Fallback Bar

    private var miniFallbackBar: some View {
        HStack(spacing: 12) {
            TTSBadgeView(
                playerState: .fallback,
                voice: "system",
                languageCode: fallbackLanguage.voiceCode
            )
            Text("Using standard voice")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button {
                TextToSpeechManager.shared.speak(
                    text: fallbackText,
                    language: fallbackLanguage
                )
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        }
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    // MARK: - Mini Waveform Icon

    private var miniWaveformIcon: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(miniLevels.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.accentColor)
                    .frame(width: 3, height: 6 + miniLevels[i] * 16)
                    .animation(.linear(duration: 0.08), value: miniLevels[i])
            }
        }
        .frame(width: 28, height: 24)
        .onAppear { startMiniTimer() }
        .onDisappear { stopMiniTimer() }
        .onChange(of: viewModel.playerState) { startMiniTimer() }
    }

    private func startMiniTimer() {
        stopMiniTimer()
        miniTimer = Timer.scheduledTimer(withTimeInterval: 1.0/20.0, repeats: true) { _ in
            updateMiniLevels()
        }
        RunLoop.main.add(miniTimer!, forMode: .common)
    }

    private func stopMiniTimer() {
        miniTimer?.invalidate()
        miniTimer = nil
    }

    private func updateMiniLevels() {
        if viewModel.playerState == .playing, let player = viewModel.audioPlayer {
            player.updateMeters()
            miniLevels = miniLevels.indices.map { i in
                let ch = i % max(1, player.numberOfChannels)
                let db = player.averagePower(forChannel: ch)
                let norm = CGFloat((db + 30) / 30).clamped(to: 0...1)
                let jitter = CGFloat.random(in: -0.08...0.08)
                return (norm + jitter).clamped(to: 0...1)
            }
        } else {
            // Gentle sine idle
            miniPhase += 0.12
            miniLevels = miniLevels.indices.map { i in
                let phase = miniPhase + Double(i) * 1.2
                return CGFloat((sin(phase) + 1) / 2) * 0.5 + 0.15
            }
        }
    }

    // MARK: - Expanded Sheet

    private var expandedPlayer: some View {
        VStack(spacing: 0) {

            // Waveform
            WaveformView(
                playerState: viewModel.playerState,
                audioPlayer: viewModel.audioPlayer
            )
            .frame(height: 52)
            .padding(.top, 28)
            .padding(.horizontal, 32)

            // Title + badge
            VStack(spacing: 6) {
                Text(chapterTitle)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                TTSBadgeView(
                    playerState: viewModel.playerState,
                    voice: viewModel.voiceLabel,
                    languageCode: fallbackLanguage.voiceCode
                )
            }
            .padding(.top, 20)
            .padding(.horizontal, 32)

            Spacer(minLength: 24)

            // Seek bar + timestamps
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { viewModel.currentTime },
                        set: { viewModel.seek(to: $0) }
                    ),
                    in: 0...max(viewModel.duration, 1)
                )
                .tint(.accentColor)
                .accessibilityLabel(NSLocalizedString("tts_seek_bar", comment: ""))

                HStack {
                    Text(formatTime(viewModel.currentTime))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatTime(viewModel.duration))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)

            // Controls row
            HStack(spacing: 0) {

                // Speed pill
                Button {
                    viewModel.nextSpeed()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(speedLabel)
                        .font(.callout.weight(.semibold))
                        .frame(width: 52, height: 36)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }

                Spacer()

                // Skip back
                Button {
                    viewModel.skipBackward()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .accessibilityLabel(NSLocalizedString("tts_skip_back", comment: ""))

                Spacer()

                // Play / Pause — hero button
                Button {
                    viewModel.togglePlayPause()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Image(systemName: playPauseIcon)
                        .font(.system(size: 28, weight: .semibold))
                        .frame(width: 64, height: 64)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 12, x: 0, y: 4)
                }
                .accessibilityLabel(viewModel.playerState == .playing
                    ? NSLocalizedString("tts_pause", comment: "")
                    : NSLocalizedString("tts_play", comment: ""))

                Spacer()

                // Skip forward
                Button {
                    viewModel.skipForward()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .accessibilityLabel(NSLocalizedString("tts_skip_forward", comment: ""))

                Spacer()

                // Balance spacer
                Color.clear.frame(width: 52, height: 36)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            Spacer(minLength: 40)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Computed Helpers

    private var playPauseIcon: String {
        viewModel.playerState == .playing ? "pause.fill" : "play.fill"
    }

    private var speedLabel: String {
        let s = viewModel.playbackSpeed
        return s == Float(Int(s)) ? "\(Int(s))x" : "\(s)x"
    }

    private var voiceSubtitle: String {
        switch viewModel.playerState {
        case .playing: return "Playing · AI Narration"
        case .paused:  return "Paused · Tap to expand"
        case .ready:   return "Ready · Tap to expand"
        default:       return "AI Narration"
        }
    }

    private var loadingTitle: String {
        if case .downloading(let p) = viewModel.playerState, p > 0 {
            return "Preparing audio…"
        }
        return NSLocalizedString("tts_preparing", comment: "")
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private func handleStateChange(_ state: VaniPlayerState) {
        switch state {
        case .ready:
            break
        case .fallback:
            showExpanded = false
            UIAccessibility.post(
                notification: .announcement,
                argument: NSLocalizedString("tts_fallback_announcement", comment: "")
            )
        default:
            break
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ActiveNarratorView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()
            ActiveNarratorView(
                viewModel: VaniPlayerViewModel(),
                fallbackText: "Preview text",
                fallbackLanguage: .english,
                chapterTitle: "Story So Far · Chapter 8"
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .preferredColorScheme(.dark)
    }
}
#endif
