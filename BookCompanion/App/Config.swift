//
//  Config.swift
//  BookCompanion
//
//  Created by Shree on 06/02/2026.
//  Updated: v1.2 — debug builds now point to dev backend
//

import Foundation

enum Config {
    
    // MARK: - API Configuration
    //
    // DEBUG builds (running from Xcode) → dev backend → dev Supabase branch
    // RELEASE builds (App Store archive) → production backend → production Supabase
    //
    // Never change the production values here without also deploying
    // the corresponding backend change to bookcompanion-api.vercel.app

#if DEBUG
    // Development — points to dev Vercel project and dev Supabase branch
    static let apiEndpoint = "https://bookcompanion-api-dev.vercel.app"
    static let appSecret = "ujxlv2MWUY/EyRV+0Rc20eGjca8GqN5V3Q5oEnuedjM="
#else
    // Production — never change this without a tested backend deploy
    static let apiEndpoint = "https://bookcompanion-api.vercel.app"
    static let appSecret = "ujxlv2MWUY/EyRV+0Rc20eGjca8GqN5V3Q5oEnuedjM="
#endif
    
    // MARK: - App Information
    
    static let appVersion = "1.1.1"
    static let appName = "BookCompanion"
    
    // MARK: - RevenueCat

    /// Public iOS API key from RevenueCat dashboard → API Keys.
    /// This is safe to ship in the binary — it is not a secret.
    static let revenueCatAPIKey = "ho8BCwkUJ4xQY/2wwTuXdw51v/VT7I"
    
    static let maxChapters = 500

    // Summary generation can take up to 2 minutes for long books.
    static let summaryTimeoutSeconds: Double = 120

    // Chat responses are short (1–3 sentences). 60s is generous;
    // a stalled stream surfaces an error instead of hanging silently.
    static let chatTimeoutSeconds: Double = 60
}
