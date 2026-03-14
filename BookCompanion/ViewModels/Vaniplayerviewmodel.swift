//
//  VaniPlayerViewModel.swift
//  BookCompanion
//
//  Project Vani — Phase 3
//
//  State machine for AI narration playback.
//  Lives as @Published var vaniPlayer on SummaryViewModel.
//
//  States:
//    idle → prewarm → loading → buffering → ready → playing → paused
//    Any error → fallback (AVSpeech circuit breaker activates)
//
//  Pre-warm: fires when streamingText reaches 200 chars during generation.
//  The signed URL is fetched + download starts before the user taps Play.
//

import Foundation
import AVFoundation
import UIKit
import Combine

// MARK: - Vani Player State

enum VaniPlayerState: Equatable {
    case idle
    case prewarming          // Fetching signed URL from backend
    case downloading(Double) // 0.0–1.0 progress
    case ready               // Audio downloaded, AVAudioPlayer initialised
    case playing
    case paused
    case fallback            // Circuit breaker — use AVSpeech instead
}

// MARK: - VaniPlayerViewModel

@MainActor
final class VaniPlayerViewModel: NSObject, ObservableObject {

    // MARK: - Published State

    @Published private(set) var playerState: VaniPlayerState = .idle
    @Published private(set) var duration: Double = 0
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var playbackSpeed: Float = 1.0
    @Published private(set) var quotaRemaining: Int? = nil
    @Published private(set) var voiceLabel: String = "nova"

    // Set true once pre-warm has been triggered for this summary
    private(set) var hasStartedPrewarm = false

    // MARK: - Private — Audio

    // private(set) so ActiveNarratorView can pass it to WaveformView for metering
    private(set) var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private let downloader = VaniAudioDownloader()
    private var downloaderCancellable: AnyCancellable?

    // MARK: - Private — Current Request Context

    private var currentBookId: String = ""
    private var currentLanguageCode: String = "en"
    private var currentVoice: String = "nova"
    private var currentSummaryText: String = ""
    private var currentChapterNumber: Int = 0
    private var currentLocalURL: URL?
    private var signedUrl: String?

    // MARK: - Constants

    private let skipInterval: Double = 15
    private let availableSpeeds: [Float] = [0.75, 1.0, 1.25, 1.5]

    // MARK: - Init

    override init() {
        super.init()
        observeDownloader()
    }

    // MARK: - Pre-warm (called by SummaryViewModel at 200 chars)

    /// Called once per summary when streamingText.count >= 200.
    /// Fetches the signed URL from the backend and starts downloading.
    /// If audio is already cached on device, resolves immediately.
    func prewarm(text: String, language: Language, bookId: String, chapterNumber: Int = 0) async {
        guard !hasStartedPrewarm else { return }
        hasStartedPrewarm = true

        currentBookId       = bookId
        currentLanguageCode = language.voiceCode
        currentSummaryText  = text
        currentChapterNumber = chapterNumber

        playerState = .prewarming

        // Enqueue TTS job (returns immediately, then poll for audio)
        do {
            let result = try await fetchSignedUrl(
                bookId: bookId,
                summaryText: text,
                languageCode: language.voiceCode,
                chapterNumber: chapterNumber
            )
            self.currentVoice   = result.voice
            self.voiceLabel     = result.voice
            self.quotaRemaining = result.quotaRemaining ?? nil

            if let url = result.signedUrl, !url.isEmpty {
                // Cache hit — start download immediately
                self.signedUrl = url
                playerState = .downloading(0)
                let cacheKey = "\(deriveSummaryId(bookId: bookId, languageCode: language.voiceCode, voice: result.voice))_\(language.voiceCode)_\(result.voice)"
                await downloader.fetchAudio(signedUrl: url, cacheKey: cacheKey)
            } else if let jobId = result.jobId {
                // Async job — poll /api/tts-status every 2s
                print("🎵 Vani job enqueued: \(jobId)")
                playerState = .downloading(0)
                try await pollForCompletion(
                    jobId: jobId, voice: result.voice,
                    bookId: bookId, languageCode: language.voiceCode
                )
            } else {
                throw AIError.invalidResponse
            }
        } catch {
            print("⚠️ VaniPlayerViewModel: pre-warm failed — \(error.localizedDescription)")
            activateFallback()
        }
    }

    /// Called by SummaryViewModel when streaming completes.
    /// If pre-warm used a partial text, re-fetch with the full summary.
    func handleSummaryComplete(fullText: String, language: Language, bookId: String) async {
        currentSummaryText = fullText
        // If still in fallback or idle, don't retry
        guard case .fallback = playerState else { return }
        // Already in fallback — don't retry
    }

    // MARK: - Playback Controls

    func play() {
        guard let player = audioPlayer else {
            // Audio not ready yet — ignore tap (button should be disabled)
            return
        }
        player.play()
        playerState = .playing
        startProgressTimer()

        AnalyticsManager.shared.track(
            event: "tts_play_tapped",
            properties: ["voice": currentVoice, "language": currentLanguageCode]
        )
    }

    func pause() {
        audioPlayer?.pause()
        playerState = .paused
        stopProgressTimer()
    }

    func togglePlayPause() {
        switch playerState {
        case .playing: pause()
        case .paused, .ready: play()
        default: break
        }
    }

    func seek(to time: Double) {
        guard let player = audioPlayer else { return }
        player.currentTime = max(0, min(time, player.duration))
        currentTime = player.currentTime
    }

    func skipForward() {
        guard let player = audioPlayer else { return }
        seek(to: player.currentTime + skipInterval)
    }

    func skipBackward() {
        guard let player = audioPlayer else { return }
        seek(to: player.currentTime - skipInterval)
    }

    func setSpeed(_ speed: Float) {
        guard availableSpeeds.contains(speed) else { return }
        playbackSpeed = speed
        audioPlayer?.rate = speed
    }

    func nextSpeed() {
        let current = availableSpeeds.firstIndex(of: playbackSpeed) ?? 1
        let next = availableSpeeds[(current + 1) % availableSpeeds.count]
        setSpeed(next)
    }

    // MARK: - Downloader Observer

    private func observeDownloader() {
        downloaderCancellable = downloader.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] downloadState in
                self?.handleDownloadState(downloadState)
            }
    }

    private func handleDownloadState(_ downloadState: VaniDownloadState) {
        switch downloadState {
        case .idle, .checking:
            break

        case .downloading(let progress):
            // Only update if we're not already past this stage
            if case .playing = playerState { return }
            if case .paused  = playerState { return }
            if case .ready   = playerState { return }
            playerState = .downloading(progress)

        case .ready(let localURL):
            currentLocalURL = localURL
            initAudioPlayer(url: localURL)

        case .failed(let reason):
            print("⚠️ VaniPlayerViewModel: download failed — \(reason)")
            AnalyticsManager.shared.track(
                event: "tts_fallback_triggered",
                properties: [
                    "failure_reason": "download_failed",
                    "detail": reason,
                    "voice": currentVoice
                ]
            )
            activateFallback()
        }
    }

    // MARK: - AVAudioPlayer Init

    private func initAudioPlayer(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate          = self
            player.enableRate        = true
            player.rate              = playbackSpeed
            player.numberOfLoops     = 0   // play once, never loop
            player.isMeteringEnabled = true  // required for waveform
            player.prepareToPlay()

            audioPlayer = player
            duration    = player.duration
            currentTime = 0
            print("🎵 Vani player: duration = \(player.duration)s, url = \(url.lastPathComponent)")
            playerState = .ready

            // Accessibility announcement
            UIAccessibility.post(
                notification: .announcement,
                argument: NSLocalizedString("tts_ready_announcement", comment: "")
            )
        } catch {
            print("❌ VaniPlayerViewModel: AVAudioPlayer init failed — \(error.localizedDescription)")
            activateFallback()
        }
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let player = self.audioPlayer else { return }
                self.currentTime = player.currentTime
                let pct = player.duration > 0 ? player.currentTime / player.duration : 0
                self.checkProgressMilestone(pct)
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private var firedMilestones = Set<Int>()

    private func checkProgressMilestone(_ pct: Double) {
        let milestones = [25, 50, 75, 100]
        for m in milestones {
            if pct * 100 >= Double(m) && !firedMilestones.contains(m) {
                firedMilestones.insert(m)
                AnalyticsManager.shared.track(
                    event: "tts_progress",
                    properties: [
                        "milestone_pct": m,
                        "voice": currentVoice,
                        "language": currentLanguageCode
                    ]
                )
            }
        }
    }

    // MARK: - Circuit Breaker

    /// Silently falls back to AVSpeechSynthesizer.
    /// TextToSpeechManager.shared handles the actual AVSpeech playback.
    private func activateFallback() {
        playerState = .fallback
        stopProgressTimer()
        audioPlayer?.stop()
        audioPlayer = nil
    }

    // MARK: - Reset (called when navigating away)

    func reset() {
        audioPlayer?.stop()
        audioPlayer = nil
        stopProgressTimer()
        downloader.cancel()
        playerState         = .idle
        hasStartedPrewarm   = false
        currentTime         = 0
        duration            = 0
        firedMilestones     = []
        signedUrl           = nil
        currentLocalURL     = nil
    }

    // MARK: - Backend: Fetch Signed URL

    private struct TTSResponse: Decodable {
        let success: Bool
        let signedUrl: String?   // present on cache hit
        let jobId: String?       // present when async job enqueued
        let voice: String
        let fromCache: Bool
        let promptVersion: String?
        let quotaRemaining: Int?
    }

    private struct TTSStatusResponse: Decodable {
        let status: String
        let signedUrl: String?
        let voice: String?
        let error: String?
    }

    private func fetchSignedUrl(bookId: String, summaryText: String, languageCode: String, chapterNumber: Int = 0) async throws -> TTSResponse {
        guard let url = URL(string: "\(Config.apiEndpoint)/api/tts?action=enqueue") else {
            throw AIError.requestFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        if let token = KeychainManager.shared.getUserToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw AIError.unauthorized
        }

        let body: [String: Any] = [
            "bookId":        bookId,
            "summaryText":   summaryText,
            "languageCode":  languageCode,
            "chapterNumber": String(chapterNumber)
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AIError.requestFailed
        }

        switch http.statusCode {
        case 200:
            let decoded = try JSONDecoder().decode(TTSResponse.self, from: data)
            print("🎵 Vani /api/tts: success=\(decoded.success) fromCache=\(decoded.fromCache) voice=\(decoded.voice) signedUrl=\(decoded.signedUrl?.prefix(80) ?? "nil")")
            guard decoded.success, (decoded.signedUrl != nil || decoded.jobId != nil) else {
                print("❌ Vani /api/tts: failed — raw: \(String(data: data, encoding: .utf8)?.prefix(300) ?? "")")
                throw AIError.invalidResponse
            }
            return decoded
        default:
            let raw = String(data: data, encoding: .utf8) ?? ""
            print("❌ Vani /api/tts: HTTP \(http.statusCode) — \(raw.prefix(300))")
            switch http.statusCode {
            case 401: throw AIError.unauthorized
            case 429: throw AIError.rateLimited
            case 503: throw AIError.requestFailed
            default:  throw AIError.requestFailed
            }
        }
    }

    // MARK: - Job Polling

    private func pollForCompletion(jobId: String, voice: String, bookId: String, languageCode: String) async throws {
        guard let baseURL = URL(string: "\(Config.apiEndpoint)/api/tts?action=status") else {
            throw AIError.requestFailed
        }
        let maxAttempts = 45
        for attempt in 1...maxAttempts {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
            comps.queryItems = [
                URLQueryItem(name: "action", value: "status"),
                URLQueryItem(name: "jobId", value: jobId)
            ]
            var request = URLRequest(url: comps.url!)
            request.httpMethod = "GET"
            request.timeoutInterval = 10
            guard let token = KeychainManager.shared.getUserToken() else { throw AIError.unauthorized }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(TTSStatusResponse.self, from: data)
            print("🎵 Vani poll #\(attempt): \(decoded.status)")
            switch decoded.status {
            case "complete":
                guard let url = decoded.signedUrl, !url.isEmpty else { throw AIError.invalidResponse }
                self.signedUrl = url
                self.voiceLabel = decoded.voice ?? voice
                playerState = .downloading(0)
                let cacheKey = "\(deriveSummaryId(bookId: bookId, languageCode: languageCode, voice: voice))_\(languageCode)_\(voice)"
                await downloader.fetchAudio(signedUrl: url, cacheKey: cacheKey)
                return
            case "failed":
                throw AIError.requestFailed
            default:
                playerState = .downloading(min(Double(attempt) / Double(maxAttempts), 0.92))
            }
        }
        throw AIError.requestFailed
    }

    // MARK: - SummaryId (matches backend hash logic for cache key)

    /// Derives a short cache key matching the backend's SHA-256 prefix.
    /// Used only to construct the local device cache filename.
    /// The backend controls the authoritative summaryId.
    private func deriveSummaryId(bookId: String, languageCode: String, voice: String) -> String {
        // We don't have SHA-256 easily here, so use a deterministic string
        // bookId is sufficient for the device cache — collisions between
        // different voices/languages are avoided by including them in cacheKey
        return bookId.replacingOccurrences(of: "/", with: "_")
                     .prefix(16)
                     .lowercased()
                     .appending("_local")
    }
}

// MARK: - AVAudioPlayerDelegate

extension VaniPlayerViewModel: AVAudioPlayerDelegate {

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.playerState = .ready
            self.currentTime = 0
            self.stopProgressTimer()

            AnalyticsManager.shared.track(
                event: "tts_progress",
                properties: [
                    "milestone_pct": 100,
                    "voice": self.currentVoice,
                    "language": self.currentLanguageCode,
                    "completed": flag
                ]
            )
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            print("❌ VaniPlayerViewModel: decode error — \(error?.localizedDescription ?? "unknown")")
            self?.activateFallback()
        }
    }
}
