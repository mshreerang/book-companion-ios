//
//  GuestManager.swift
//  BookCompanion
//
//  Manages guest mode quota and device fingerprint.
//
//  Flow:
//    1. User taps "Continue as Guest" on onboarding
//    2. GuestManager.shared.enterGuestMode() sets isGuestMode = true
//    3. Before any AI action, call checkQuota(type:) — returns allowed/blocked
//    4. After successful generation, call increment(type:)
//    5. When guest creates account or signs in, call linkDevice(userId:)
//       so fraud detection works on future guest attempts from same device
//
//  Device fingerprint:
//    UIDevice.current.identifierForVendor is hashed (SHA-256) client-side.
//    The raw UUID is never sent to the backend.
//    Resets on app reinstall — acceptable, blocks casual abuse not sophisticated attacks.

import Foundation
import UIKit
import CryptoKit
import Combine

// MARK: - Guest Quota Result

struct GuestQuotaResult {
  let allowed: Bool
  let used: Int
  let limit: Int
  let remaining: Int
}

// MARK: - GuestManager

@MainActor
final class GuestManager: ObservableObject {

  static let shared = GuestManager()

  // ── Published state ────────────────────────────────────────────────────────

  /// True when the user is operating in guest mode (no account)
  @Published private(set) var isGuestMode: Bool = false

  /// Local quota cache — avoids network round-trip for every UI check
  @Published private(set) var summariesUsed:   Int = 0
  @Published private(set) var charactersUsed:  Int = 0
  @Published private(set) var chatUsed:        Int = 0

  // ── Constants ──────────────────────────────────────────────────────────────

  let summaryLimit:   Int = 1
  let characterLimit: Int = 1
  let chatLimit:      Int = 5

  // Convenience computed properties for views
  var summariesRemaining:  Int { max(0, summaryLimit   - summariesUsed)  }
  var charactersRemaining: Int { max(0, characterLimit - charactersUsed) }
  var chatRemaining:       Int { max(0, chatLimit      - chatUsed)       }

  var hasAnySummaryLeft:   Bool { summariesRemaining  > 0 }
  var hasAnyCharacterLeft: Bool { charactersRemaining > 0 }
  var hasAnyChatLeft:      Bool { chatRemaining       > 0 }

  // ── Device fingerprint ─────────────────────────────────────────────────────

  /// SHA-256 hash of identifierForVendor as a hex string (64 chars)
  /// Returns a stable fallback if identifierForVendor is unavailable
  private(set) lazy var deviceHash: String = {
    let raw = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    let data = Data(raw.utf8)
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
  }()

  private init() {}

  // MARK: - Enter / Exit Guest Mode

  func enterGuestMode() {
    isGuestMode = true
    // Fetch current usage from backend in case they've been a guest before
    Task { await fetchUsage() }
  }

  func exitGuestMode() {
    isGuestMode = false
  }

  // MARK: - Check Quota

  /// Call before any AI action. Returns allowed/blocked.
  /// Falls back to local cache if network is unavailable.
  func checkQuota(type: String) async -> GuestQuotaResult {
    guard let url = URL(string: "\(Config.apiEndpoint)/api/guest") else {
      return localResult(type: type)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 8

    let body: [String: Any] = [
      "action":     "check",
      "deviceHash": deviceHash,
      "type":       type
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    do {
      let (data, _) = try await URLSession.shared.data(for: request)
      if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        let allowed   = json["allowed"]   as? Bool ?? true
        let used      = json["used"]      as? Int  ?? 0
        let limit     = json["limit"]     as? Int  ?? localLimit(type: type)
        let remaining = json["remaining"] as? Int  ?? max(0, limit - used)

        // Sync local cache
        updateLocalCache(type: type, used: used)

        return GuestQuotaResult(allowed: allowed, used: used, limit: limit, remaining: remaining)
      }
    } catch {
      print("⚠️ GuestManager.checkQuota network error — using local cache: \(error)")
    }

    return localResult(type: type)
  }

  // MARK: - Increment

  /// Call after a successful generation to record usage.
  /// Fire-and-forget — never blocks the UI.
  func increment(type: String) {
    // Update local cache immediately for responsive UI
    switch type {
    case "summary":   summariesUsed  = min(summariesUsed  + 1, summaryLimit)
    case "character": charactersUsed = min(charactersUsed + 1, characterLimit)
    case "chat":      chatUsed       = min(chatUsed       + 1, chatLimit)
    default: break
    }

    // Fire backend increment (fire-and-forget)
    Task {
      guard let url = URL(string: "\(Config.apiEndpoint)/api/guest") else { return }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.timeoutInterval = 8

      let body: [String: Any] = [
        "action":     "increment",
        "deviceHash": deviceHash,
        "type":       type
      ]
      request.httpBody = try? JSONSerialization.data(withJSONObject: body)
      _ = try? await URLSession.shared.data(for: request)
    }
  }

  // MARK: - Link Device to Account

  /// Call immediately after a guest creates an account or signs in.
  /// Links the device hash to their userId for fraud detection.
  /// Fire-and-forget — never blocks sign-in.
  func linkDevice(userId: String) {
    exitGuestMode()
    Task {
      guard let url = URL(string: "\(Config.apiEndpoint)/api/guest") else { return }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.timeoutInterval = 8

      let body: [String: Any] = [
        "action":     "link",
        "deviceHash": deviceHash,
        "userId":     userId
      ]
      request.httpBody = try? JSONSerialization.data(withJSONObject: body)
      _ = try? await URLSession.shared.data(for: request)
      print("✅ GuestManager: device linked to userId \(userId)")
    }
  }

  // MARK: - Fetch Usage (sync from backend)

  func fetchUsage() async {
    // We use the check endpoint for each type to get current counts
    // This is only called on enterGuestMode() — once per guest session
    async let s = checkQuota(type: "summary")
    async let c = checkQuota(type: "character")
    async let ch = checkQuota(type: "chat")

    let (sr, cr, chr) = await (s, c, ch)
    summariesUsed  = sr.used
    charactersUsed = cr.used
    chatUsed       = chr.used
  }

  // MARK: - Private helpers

  private func localLimit(type: String) -> Int {
    switch type {
    case "summary":   return summaryLimit
    case "character": return characterLimit
    case "chat":      return chatLimit
    default:          return 0
    }
  }

  private func localResult(type: String) -> GuestQuotaResult {
    let used  = type == "summary" ? summariesUsed : type == "character" ? charactersUsed : chatUsed
    let limit = localLimit(type: type)
    return GuestQuotaResult(allowed: used < limit, used: used, limit: limit, remaining: max(0, limit - used))
  }

  private func updateLocalCache(type: String, used: Int) {
    switch type {
    case "summary":   summariesUsed  = used
    case "character": charactersUsed = used
    case "chat":      chatUsed       = used
    default: break
    }
  }
}
