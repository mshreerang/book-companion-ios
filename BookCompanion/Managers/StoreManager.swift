//
//  StoreManager.swift
//  BookCompanion
//
//  Created by Shree on 28/02/2026.
//

import Foundation
import RevenueCat
import Combine

// MARK: - RCDelegate

final class RCDelegate: NSObject, PurchasesDelegate {
    static let shared = RCDelegate()
    private override init() {}

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            StoreManager.shared.updateState(from: customerInfo)
        }
    }
}

// MARK: - StoreManager

@MainActor
final class StoreManager: ObservableObject {

    static let shared = StoreManager()

    @Published private(set) var isPro: Bool = false
    @Published private(set) var isFoundingMember: Bool = false
    @Published private(set) var subscriptionStatus: String = "free"
    @Published private(set) var offerings: Offerings?
    @Published var purchaseError: String?
    @Published var isPurchasing: Bool = false
    @Published var topupProduct: StoreProduct? = nil
    @Published var isTopupPurchasing: Bool = false
    @Published var topupPurchaseSucceeded: Bool = false

    // ── Top-up credit counts ──────────────────────────────────────────────────
    // Fetched from /api/usage/stats when PaywallView appears or after a purchase.
    // Also updated in real-time from the SSE done event in SummaryViewModel.
    // These never reset on the 1st — they persist until consumed.
    @Published var topupSummaryCredits:   Int = 0
    @Published var topupCharacterCredits: Int = 0
    @Published var topupChatCredits:      Int = 0

    private init() {}

    // MARK: - Configure
    // NOT nonisolated — called via Task { await } from App.init().
    // See BookCompanionApp.swift for the call site pattern.

    func configure() {
        let apiKey = "appl_QfNuJzvDdTJLNcrfJBbLKiwRlCH"
        Purchases.logLevel = .error
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = RCDelegate.shared
        Task { await syncEntitlementCached() }
    }

    // MARK: - Login

    func login(userId: String) async {
        do {
            _ = try await Purchases.shared.logIn(userId)
            // After login, always fetch fresh entitlements from RevenueCat
            await syncEntitlement()
        } catch {
            print("❌ RC login error: \(error)")
        }
    }

    // MARK: - Sync (foreground — always fresh from network)
    // Uses .fetchCurrent to force a network call to RevenueCat.
    // This ensures we never show stale entitlement state after a purchase or login.

    func syncEntitlement() async {
        do {
            let info = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
            updateState(from: info)
        } catch {
            print("⚠️ RC entitlement sync failed — keeping cached state: \(error)")
        }
    }

    // MARK: - Sync (cold launch — cache first, network fallback)
    // Used only on app launch to avoid blocking the UI with a network call.
    // Falls back to a fresh fetch if cache is empty.

    func syncEntitlementCached() async {
        do {
            let info = try await Purchases.shared.customerInfo(fetchPolicy: .fromCacheOnly)
            updateState(from: info)
        } catch {
            // Cache miss — fall back to network
            await syncEntitlement()
        }
    }

    // MARK: - Load Offerings

    func loadOfferings() async {
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            print("❌ RC offerings error: \(error)")
        }
    }

    // MARK: - Load Top-Up Product

    func loadTopupProduct() async {
        await withCheckedContinuation { continuation in
            Purchases.shared.getProducts(["com.vivanLabs.BookCompanion.topup.pack"]) { products in
                Task { @MainActor in
                    self.topupProduct = products.first
                }
                continuation.resume()
            }
        }
    }

    // MARK: - Fetch Top-Up Credit Counts
    // Called when PaywallView appears and after a successful top-up purchase.
    // Reads from /api/usage/stats which returns all three credit fields.
    // Also called by UsageStatsViewModel.loadUsage() to keep counts fresh.

    func fetchTopupCredits() async {
        guard let token = KeychainManager.shared.getUserToken() else { return }
        guard let url = URL(string: "\(Config.apiEndpoint)/api/usage/stats") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                topupSummaryCredits   = json["topup_summary_credits"]   as? Int ?? 0
                topupCharacterCredits = json["topup_character_credits"] as? Int ?? 0
                topupChatCredits      = json["topup_chat_credits"]      as? Int ?? 0
            }
        } catch {
            print("⚠️ fetchTopupCredits failed: \(error)")
        }
    }

    // MARK: - Purchase Top-Up
    // Consumables use purchase(product:) not purchase(package:).
    // They do not grant entitlements — the NON_SUBSCRIPTION_PURCHASE
    // webhook fires and our backend grants the credits.

    func purchaseTopup() async -> Bool {
        guard let product = topupProduct else {
            purchaseError = "Top-up pack unavailable. Please try again."
            return false
        }
        isTopupPurchasing = true
        purchaseError = nil
        do {
            let (_, _, cancelled) = try await Purchases.shared.purchase(product: product)
            isTopupPurchasing = false
            if !cancelled {
                topupPurchaseSucceeded = true
                // Refresh credit counts from server after purchase
                await fetchTopupCredits()
                // Reset flag after brief delay so views can observe the change
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                topupPurchaseSucceeded = false
            }
            return !cancelled
        } catch {
            isTopupPurchasing = false
            purchaseError = error.localizedDescription
            return false
        }
    }

    // MARK: - Purchase
    // After a successful purchase:
    //   1. updateState immediately from the purchase result (fast, local)
    //   2. syncEntitlement fetches fresh from network (confirms with RC server)
    // This two-step approach ensures the UI updates instantly while also
    // confirming the entitlement with RevenueCat's server.

    func purchase(package: Package) async -> Bool {
        isPurchasing = true
        purchaseError = nil
        do {
            let (_, info, cancelled) = try await Purchases.shared.purchase(package: package)
            isPurchasing = false
            if !cancelled {
                // Step 1 — immediate local update from purchase result
                updateState(from: info)
                // Step 2 — force fresh network sync to confirm with RC server
                await syncEntitlement()
            }
            return !cancelled
        } catch {
            isPurchasing = false
            purchaseError = error.localizedDescription
            return false
        }
    }

    // MARK: - Restore
    // Always fetches fresh after restore to confirm entitlements.

    @discardableResult
    func restorePurchases() async -> Bool {
        isPurchasing = true
        purchaseError = nil
        do {
            let info = try await Purchases.shared.restorePurchases()
            updateState(from: info)
            // Confirm with a fresh network fetch
            await syncEntitlement()
            isPurchasing = false
            return isPro
        } catch {
            purchaseError = "Restore failed: \(error.localizedDescription)"
            isPurchasing = false
            return false
        }
    }

    // MARK: - State Update

    func updateState(from info: CustomerInfo) {
        isPro = info.entitlements["pro"]?.isActive == true
        subscriptionStatus = isPro ? "pro" : "free"
    }
}
