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

    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    // Show only onboarding
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
    init() {
        // Initialize showOnboarding based on UserDefaults
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        _showOnboarding = State(initialValue: !hasCompleted)
    }
}
