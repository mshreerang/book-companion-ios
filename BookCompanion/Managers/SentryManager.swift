//
//  SentryManager.swift
//  BookCompanion
//
//  Created by Shree on 24/02/2026.
//

import Foundation
import Sentry

final class SentryManager {
    
    static let shared = SentryManager()
    
    private init() {}
    
    // ✅ Initialize Sentry (call from App init)
    func configure() {
        SentrySDK.start { options in
            // ✅ YOUR SENTRY DSN
            options.dsn = "https://7d32876b1e252cbada8020a60f0a4a00@o4510943351472128.ingest.de.sentry.io/4510943363530832"
            
            // Debug mode (disable in production)
            options.debug = false
            
            // Sample rate (100% for beta, reduce in production)
            options.tracesSampleRate = 1.0
            
            // Enable automatic breadcrumbs
            options.enableAutoSessionTracking = true
            options.enableAutoBreadcrumbTracking = true
            options.enableAutoPerformanceTracing = true
            
            // Set environment
            #if DEBUG
            options.environment = "debug"
            #else
            options.environment = "production"
            #endif
            
            // Attach screenshots on errors
            options.attachScreenshot = true
            options.attachViewHierarchy = true
        }
    }
    
    // ✅ Log non-fatal errors
    func logError(_ error: Error, context: [String: Any]? = nil) {
        SentrySDK.capture(error: error) { scope in
            if let context = context {
                scope.setContext(value: context, key: "custom")
            }
        }
    }
    
    // ✅ Log custom messages
    func logMessage(_ message: String, level: SentryLevel = .info) {
        let event = Event(level: level)
        event.message = SentryMessage(formatted: message)
        SentrySDK.capture(event: event)
    }
    
    // ✅ Set user context (after sign in)
    func setUser(id: String, email: String?) {
        let user = Sentry.User()
        user.userId = id
        if let email = email {
            user.email = email
        }
        SentrySDK.setUser(user)
    }
    
    // ✅ Clear user context (on sign out)
    func clearUser() {
        SentrySDK.setUser(nil)
    }
    
    // ✅ Add breadcrumb (track user actions)
    func addBreadcrumb(message: String, category: String = "user_action") {
        let crumb = Breadcrumb()
        crumb.message = message
        crumb.category = category
        crumb.level = .info
        SentrySDK.addBreadcrumb(crumb)
    }
    
    // ✅ Capture performance transaction
    func startTransaction(name: String, operation: String) -> Span? {
        return SentrySDK.startTransaction(name: name, operation: operation)
    }
}
