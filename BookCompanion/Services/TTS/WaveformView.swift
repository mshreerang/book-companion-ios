//
//  WaveformView.swift
//  BookCompanion
//
//  Project Vani — Phase 3
//
//  32-bar animated waveform visualiser.
//  - Playing: bars animate to AVAudioPlayer metering levels at 30fps
//  - Paused/Ready: gentle idle pulse using sine wave
//  - Downloading: skeleton shimmer pattern
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - WaveformView

struct WaveformView: View {

    // MARK: - Input

    let playerState: VaniPlayerState
    let audioPlayer: AVAudioPlayer?

    // MARK: - Constants

    private let barCount    = 32
    private let barSpacing  : CGFloat = 3
    private let minBarHeight: CGFloat = 4
    private let maxBarHeight: CGFloat = 40
    private let barWidth    : CGFloat = 3
    private let barCorner   : CGFloat = 2

    // MARK: - State

    @State private var levels: [CGFloat]
    @State private var idlePhase: Double = 0
    @State private var displayLink: Any? = nil // holds the Timer reference

    // MARK: - Init

    init(playerState: VaniPlayerState, audioPlayer: AVAudioPlayer?) {
        self.playerState = playerState
        self.audioPlayer = audioPlayer
        _levels = State(initialValue: Array(repeating: 0.15, count: 32))
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: barCorner)
                    .fill(barColor(for: index))
                    .frame(width: barWidth, height: barHeight(at: index))
                    .animation(
                        .spring(response: 0.15, dampingFraction: 0.6),
                        value: levels[index]
                    )
            }
        }
        .frame(height: maxBarHeight)
        .onAppear { startAnimating() }
        .onDisappear { stopAnimating() }
        .onChange(of: playerState) {
            stopAnimating()
            startAnimating()
        }
        // Accessibility
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHidden(false)
    }

    // MARK: - Bar Geometry

    private func barHeight(at index: Int) -> CGFloat {
        let normalised = levels[index].clamped(to: 0...1)
        return minBarHeight + normalised * (maxBarHeight - minBarHeight)
    }

    private func barColor(for index: Int) -> Color {
        switch playerState {
        case .playing:
            // Gradient from accent to lighter towards edges
            let centre = Double(barCount / 2)
            let dist   = abs(Double(index) - centre) / centre
            return Color.accentColor.opacity(1.0 - dist * 0.4)
        case .paused, .ready:
            return Color.accentColor.opacity(0.5)
        case .downloading:
            return Color.gray.opacity(0.3)
        default:
            return Color.gray.opacity(0.2)
        }
    }

    // MARK: - Animation Loop

    private func startAnimating() {
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            updateLevels()
        }
        RunLoop.main.add(timer, forMode: .common)
        displayLink = timer
    }

    private func stopAnimating() {
        (displayLink as? Timer)?.invalidate()
        displayLink = nil
    }

    private func updateLevels() {
        switch playerState {

        case .playing:
            guard let player = audioPlayer else {
                setIdleLevels()
                return
            }
            player.updateMeters()
            var newLevels = [CGFloat]()
            for i in 0..<barCount {
                // Map two channels across 32 bars
                let channel = i % max(1, player.numberOfChannels)
                let db      = player.averagePower(forChannel: channel)
                // Speech sits in -30..0 dB range — use that for full bar travel
                let normalised = CGFloat((db + 30) / 30).clamped(to: 0...1)
                // Add slight randomness for organic feel
                let jitter = CGFloat.random(in: -0.05...0.05)
                newLevels.append((normalised + jitter).clamped(to: 0...1))
            }
            withAnimation(nil) { levels = newLevels }

        case .paused, .ready:
            // Gentle sine-wave idle pulse
            idlePhase += 0.05
            var newLevels = [CGFloat]()
            for i in 0..<barCount {
                let phase  = idlePhase + Double(i) * (2 * .pi / Double(barCount))
                let value  = CGFloat((sin(phase) + 1) / 2) * 0.35 + 0.1
                newLevels.append(value)
            }
            withAnimation(.linear(duration: 1.0 / 30.0)) { levels = newLevels }

        case .downloading:
            // Skeleton shimmer — single travelling bar
            idlePhase += 0.12
            var newLevels = [CGFloat]()
            for i in 0..<barCount {
                let normI  = Double(i) / Double(barCount)
                let wave   = CGFloat((sin(idlePhase - normI * .pi * 2) + 1) / 2) * 0.25 + 0.05
                newLevels.append(wave)
            }
            withAnimation(.linear(duration: 1.0 / 30.0)) { levels = newLevels }

        default:
            setIdleLevels()
        }
    }

    private func setIdleLevels() {
        withAnimation(.easeOut(duration: 0.3)) {
            levels = Array(repeating: 0.1, count: barCount)
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        switch playerState {
        case .playing:    return NSLocalizedString("tts_waveform_playing", comment: "")
        case .paused:     return NSLocalizedString("tts_waveform_paused", comment: "")
        case .downloading: return NSLocalizedString("tts_waveform_loading", comment: "")
        default:          return ""
        }
    }
}

// MARK: - Comparable clamp helper

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
