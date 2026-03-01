//
//  Config.swift
//  BookCompanion
//
//  Created by Shree on 06/02/2026.
//

import Foundation

enum Config {
    
    // MARK: - API Configuration
    
#if DEBUG
// Development
static let apiEndpoint = "https://bookcompanion-api.vercel.app"
static let appSecret = "ujxlv2MWUY/EyRV+0Rc20eGjca8GqN5V3Q5oEnuedjM="
#else
// Production
static let apiEndpoint = "https://bookcompanion-api.vercel.app"
static let appSecret = "ujxlv2MWUY/EyRV+0Rc20eGjca8GqN5V3Q5oEnuedjM="
#endif
    
    // MARK: - App Information
    
    static let appVersion = "1.0.0"
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
