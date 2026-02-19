//
//  BookCompanionApp.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//

import SwiftUI

@main
struct BookCompanionApp: App {

    private let container = AppContainer()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding: Bool
    @StateObject private var bookManager = BookManager()
    
    init() {
        // Initialize showOnboarding based on UserDefaults
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        _showOnboarding = State(initialValue: !hasCompleted)
        
        // ✅ Configure image cache
        let cache = URLCache(
            memoryCapacity: 50_000_000,   // 50 MB in RAM
            diskCapacity: 100_000_000     // 100 MB on disk
        )
        URLCache.shared = cache
        
        print("📦 Image cache configured: 50 MB memory, 100 MB disk")
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    // Show onboarding (with age verification on page 3)
                    OnboardingView {
                        showOnboarding = false
                    }
                } else {
                    // Show main app
                    NavigationStack {
                        BookSearchView(
                            viewModel: container.makeBookSearchViewModel(),
                            settingsManager: container.settingsManager,
                            bookManager: container.bookManager,
                            makeProgressViewModel: container.makeProgressInputViewModel,
                            makeSummaryViewModel: container.makeSummaryViewModel,
                            makeCharactersViewModel: container.makeCharactersViewModel
                        )
                    }
                }
            }
        }
    }
}
