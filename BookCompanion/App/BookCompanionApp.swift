//
//  BookCompanionApp.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
import SwiftUI
import Combine
import Sentry
import RevenueCat

@main
struct BookCompanionApp: App {
    
    private let container = AppContainer()
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var storeManager = StoreManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenTransparencyScreen") private var hasSeenTransparencyScreen = false
    @State private var showOnboarding: Bool
    @State private var showTransparency = false
    @StateObject private var bookManager = BookManager()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // 0. Analytics first
        AnalyticsManager.shared.configure()

        // 0b. RevenueCat — configure on main actor via Task
        Task { @MainActor in
            StoreManager.shared.configure()
        }

        // 1. Check onboarding status
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        _showOnboarding = State(initialValue: !hasCompleted)
        
        // 2. Configure image cache
        let cache = URLCache(
            memoryCapacity: 50_000_000,
            diskCapacity: 100_000_000
        )
        URLCache.shared = cache
        
        // 3. Configure Sentry
        SentrySDK.start { options in
            options.dsn = "https://7d32876b1e252cbada8020a60f0a4a00@o4510943351472128.ingest.de.sentry.io/4510943363530832"
            options.sendDefaultPii = true
            options.tracesSampleRate = 1.0
            options.configureProfiling = { profilingOptions in
                profilingOptions.sessionSampleRate = 1.0
                profilingOptions.lifecycle = .trace
            }
            options.attachScreenshot = true
            options.attachViewHierarchy = true
            #if DEBUG
            options.environment = "debug"
            #else
            options.environment = "production"
            #endif
        }
        
        SentrySDK.capture(message: "BookCompanion launched! 🚀")
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    OnboardingView {
                        showOnboarding = false
                    }
                } else if !authManager.isSignedIn {
                    SignInView(authManager: authManager)
                } else {
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
                    .task {
                        await container.bookManager.syncFromCloud()
                    }
                    // Show transparency screen once after first sign-in
                    .fullScreenCover(isPresented: $showTransparency) {
                        TransparencyOnboardingView {
                            hasSeenTransparencyScreen = true
                            showTransparency = false
                        }
                    }
                    .onAppear {
                        if !hasSeenTransparencyScreen {
                            // Small delay so main UI renders first
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showTransparency = true
                            }
                        }
                    }
                }
            }
            .environmentObject(authManager)
            .environmentObject(storeManager)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await StoreManager.shared.syncEntitlement() }
                }
            }
        }
    }
}
