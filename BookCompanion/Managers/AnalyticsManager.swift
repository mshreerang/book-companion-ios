//
//  AnalyticsManager.swift
//  BookCompanion
//
//  Created by Shree on 25/02/2026.
//

import Foundation
import PostHog

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private var isConfigured = false
    
    private init() {}
    
    func configure() {
        guard !isConfigured else { return }
        
        // ✅ CRITICAL: Include the EU host URL
        let POSTHOG_HOST = "https://eu.i.posthog.com"
        let configuration = PostHogConfig(
            apiKey: "phc_Raf2CphadTsbB5YzTK9NA78caycYk9kCVF9tph0R3fQ",
            host: POSTHOG_HOST
        )
        
        configuration.captureApplicationLifecycleEvents = true
        configuration.captureScreenViews = true
        
        PostHogSDK.shared.setup(configuration)
        
        isConfigured = true
        print("✅ Analytics configured with PostHog (EU server)")
        
        // ✅ TEST: Send a test event immediately
        PostHogSDK.shared.capture("app_launched")
        print("📊 Test event sent: app_launched")
    }
    
    // Identify user (call after sign in)
    func identify(userId: String, properties: [String: Any] = [:]) {
        var props = properties
        props["platform"] = "iOS"
        props["app_version"] = Bundle.main.appVersion
        
        // ✅ CORRECT: PostHog identify
        PostHogSDK.shared.identify(
            userId,
            userProperties: props
        )
        
        print("✅ User identified: \(userId)")
    }
    
    // Track event
    func track(event: String, properties: [String: Any] = [:]) {
        // ✅ CORRECT: PostHog capture
        PostHogSDK.shared.capture(event, properties: properties)
        
        #if DEBUG
        print("📊 Analytics: \(event)")
        if !properties.isEmpty {
            print("   Properties: \(properties)")
        }
        #endif
    }
    
    // Reset (call on sign out)
    func reset() {
        PostHogSDK.shared.reset()
        print("✅ Analytics reset")
    }
}

// Helper extension
extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
