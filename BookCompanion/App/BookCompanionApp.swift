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
    
    // ── ADDITION 1: AppDelegate adaptor for APNs token bridge ────────────────
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let container = AppContainer()
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var storeManager = StoreManager.shared
    @StateObject private var guestManager = GuestManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var bookManager = BookManager()
    @StateObject private var deepLinkManager = DeepLinkManager()
    @StateObject private var usageManager = UsageManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    
    init() {
        // 0. Analytics first
        AnalyticsManager.shared.configure()

        // 0b. RevenueCat — configure on main actor via Task
        Task { @MainActor in
            StoreManager.shared.configure()
        }

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
                if !hasCompletedOnboarding {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                } else if guestManager.isGuestMode {
                    // ── Guest mode — no account, limited quota ────────────
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
                }
            }
            .environmentObject(authManager)
            .environmentObject(storeManager)
            .environmentObject(guestManager)
            .environmentObject(deepLinkManager)
            .environmentObject(usageManager)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await StoreManager.shared.syncEntitlement() }
                    NotificationManager.shared.clearBadge()
                }
            }
            // When user signs in from guest mode, link device → userId
            .onChange(of: authManager.isSignedIn) { _, signedIn in
                if signedIn, let userId = authManager.userId {
                    GuestManager.shared.linkDevice(userId: userId)
                }
                // ── ADDITION 2: Request push permission on sign-in ───────
                if signedIn {
                    NotificationManager.shared.requestPermission()
                }
                if signedIn {
                    UsageManager.shared.refresh()
                }
            }
            .onOpenURL { url in
                deepLinkManager.handle(url: url)
            }
            // ── ADDITION 3: Receive APNs token from AppDelegate bridge ───
            .onReceive(NotificationCenter.default.publisher(
                for: Notification.Name("APNSTokenReceived")
            )) { notification in
                if let tokenData = notification.object as? Data {
                    NotificationManager.shared.registerToken(tokenData)
                }
            }
        }
    }
}

// MARK: - AppDelegate (APNs token bridge)
//
// SwiftUI apps have no AppDelegate by default, but APNs requires
// didRegisterForRemoteNotificationsWithDeviceToken to receive the token.
// We bridge it to NotificationCenter so BookCompanionApp can receive it
// without coupling AppDelegate directly to NotificationManager.

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationCenter.default.post(
            name: Notification.Name("APNSTokenReceived"),
            object: deviceToken
        )
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Non-fatal — app works without push notifications
        print("⚠️ APNs registration failed: \(error)")
    }
}
