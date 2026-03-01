//
//  FeatureFlags.swift
//  BookCompanion
//
//  Created by Shree on 27/02/2026.
//

import Foundation

// MARK: - FeatureFlags
//
// Single source of truth for all feature toggles.
// To enable Character Chat for launch: set `characterChat = true`.
// No other code changes required.
//
// Convention: add new flags here before building the feature.
// Never scatter flag checks across the codebase — always read from here.

enum FeatureFlags {

    // ─────────────────────────────────────────────
    //  CHARACTER CHAT
    //  Gated on Pro entitlement — Pro users see the chat button,
    //  free users see the paywall when they attempt to access it.
    //  Set to `true` to enable for all users regardless of tier (debug only).
    // ─────────────────────────────────────────────
    static var characterChat: Bool {
        StoreManager.shared.isPro
    }

    // ─────────────────────────────────────────────
    //  Future flags go here, e.g.:
    //  static let audioNarration: Bool = false
    //  static let socialHighlights: Bool = false
    // ─────────────────────────────────────────────
}
