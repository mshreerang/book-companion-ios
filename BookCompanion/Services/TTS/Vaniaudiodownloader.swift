//
//  VaniAudioDownloader.swift
//  BookCompanion
//
//  Project Vani — Phase 3
//
//  Responsibilities:
//    - Check device Caches directory before hitting the network
//    - Download signed URL → local .mp3 with progress reporting
//    - Retry once on failure (3s delay)
//    - Sweep files older than 7 days on init
//

import Foundation
import Combine

// MARK: - Download State

enum VaniDownloadState: Equatable {
    case idle
    case checking          // Checking device cache
    case downloading(Double) // 0.0 – 1.0
    case ready(URL)        // Local file URL, ready for AVAudioPlayer
    case failed(String)
}

// MARK: - VaniAudioDownloader

final class VaniAudioDownloader: NSObject, ObservableObject {

    // MARK: - Published

    @Published private(set) var state: VaniDownloadState = .idle

    // MARK: - Private

    private var urlSession: URLSession!
    private var downloadTask: URLSessionDownloadTask?
    private var progressCancellable: AnyCancellable?

    // MARK: - Init

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 120
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        sweepOldFiles()
    }

    // MARK: - Public API

    /// Main entry point. Checks device cache first, then downloads from signedUrl.
    /// Returns the local file URL via state publisher.
    func fetchAudio(signedUrl: String, cacheKey: String) async {
        await MainActor.run { state = .checking }

        // 1. Device cache check
        let localURL = localCachePath(for: cacheKey)
        if FileManager.default.fileExists(atPath: localURL.path) {
            await MainActor.run { state = .ready(localURL) }
            return
        }

        // 2. Download
        await download(from: signedUrl, to: localURL, attempt: 1)
    }

    func cancel() {
        downloadTask?.cancel()
        downloadTask = nil
        Task { @MainActor in state = .idle }
    }

    // MARK: - Cache Path

    /// Deterministic local path: Caches/vani_{cacheKey}.mp3
    /// cacheKey = "{summaryId}_{languageCode}_{voice}" — matches Storage filename
    func localCachePath(for cacheKey: String) -> URL {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("vani_\(cacheKey).mp3")
    }

    // MARK: - Download

    private func download(from signedUrl: String, to localURL: URL, attempt: Int) async {
        guard let url = URL(string: signedUrl) else {
            await MainActor.run { state = .failed("Invalid audio URL") }
            return
        }

        await MainActor.run { state = .downloading(0.0) }

        return await withCheckedContinuation { continuation in
            downloadTask = urlSession.downloadTask(with: url) { [weak self] tempURL, response, error in
                guard let self else { continuation.resume(); return }

                if let error = error {
                    if attempt < 2 {
                        // Retry once after 3 seconds
                        print("⚠️ VaniAudioDownloader: attempt \(attempt) failed — retrying in 3s: \(error.localizedDescription)")
                        Task {
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            await self.download(from: signedUrl, to: localURL, attempt: attempt + 1)
                            continuation.resume()
                        }
                    } else {
                        Task { @MainActor in
                            self.state = .failed("Download failed: \(error.localizedDescription)")
                        }
                        continuation.resume()
                    }
                    return
                }

                guard let tempURL else {
                    Task { @MainActor in self.state = .failed("No file received") }
                    continuation.resume()
                    return
                }

                // Move from temp to Caches
                do {
                    // ── Debug: HTTP status + file size ───────────────────
                    if let http = response as? HTTPURLResponse {
                        let ct = http.value(forHTTPHeaderField: "Content-Type") ?? "unknown"
                        print("🎵 Vani download: HTTP \(http.statusCode) Content-Type: \(ct)")
                    }
                    let attrs = try? FileManager.default.attributesOfItem(atPath: tempURL.path)
                    let fileSize = attrs?[.size] as? Int ?? 0
                    print("🎵 Vani download: file size = \(fileSize) bytes at \(tempURL.lastPathComponent)")

                    // Guard: if file is too small it's an error response not audio
                    if fileSize < 1024 {
                        let preview = (try? String(contentsOf: tempURL, encoding: .utf8)) ?? "binary"
                        print("❌ Vani download: suspicious file — content preview: \(preview.prefix(400))")
                        Task { @MainActor in self.state = .failed("Invalid audio response (\(fileSize) bytes)") }
                        continuation.resume()
                        return
                    }
                    // ─────────────────────────────────────────────────────

                    // Remove stale file if it exists
                    if FileManager.default.fileExists(atPath: localURL.path) {
                        try FileManager.default.removeItem(at: localURL)
                    }
                    try FileManager.default.moveItem(at: tempURL, to: localURL)
                    print("✅ Vani download: saved \(localURL.lastPathComponent)")
                    Task { @MainActor in self.state = .ready(localURL) }
                } catch {
                    Task { @MainActor in self.state = .failed("Could not save audio: \(error.localizedDescription)") }
                }

                continuation.resume()
            }
            downloadTask?.resume()
        }
    }

    // MARK: - 7-Day Cache Sweep

    /// Called once on init. Deletes vani_*.mp3 files older than 7 days.
    private func sweepOldFiles() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        let cutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago

        for file in files where file.lastPathComponent.hasPrefix("vani_") && file.pathExtension == "mp3" {
            if let created = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate,
               created < cutoff {
                try? FileManager.default.removeItem(at: file)
                print("🧹 VaniAudioDownloader: swept \(file.lastPathComponent)")
            }
        }
    }
}

// MARK: - URLSessionDownloadDelegate (progress)

extension VaniAudioDownloader: URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task { @MainActor [weak self] in
            // Only update if still downloading (don't overwrite ready/failed)
            if case .downloading = self?.state {
                self?.state = .downloading(progress)
            }
        }
    }

    // Required by URLSessionDownloadDelegate but handled in completion handler above
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // Intentionally empty — handled in the completion closure in download()
    }
}
