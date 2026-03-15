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
    //  Available to all signed-in users.
    //  Free users get 5 messages per character per book (enforced backend).
    //  Pro users get unlimited messages.
    //  The quota gate is handled server-side — no iOS tier check needed here.
    // ─────────────────────────────────────────────
    static let characterChat: Bool = true

    // ─────────────────────────────────────────────
    //  SERIES TRACKING
    //  Enables series detection in ConfirmBookView and
    //  cross-book AI context injection in summaries.
    // ─────────────────────────────────────────────
    static let seriesTracking: Bool = true

    // ─────────────────────────────────────────────
    //  Future flags go here, e.g.:
    //  static let audioNarration: Bool = false
    //  static let socialHighlights: Bool = false
    // ─────────────────────────────────────────────
}
