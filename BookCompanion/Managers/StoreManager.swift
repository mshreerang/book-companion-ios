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
            await syncEntitlement()
        } catch {
            print("❌ RC login error: \(error)")
        }
    }

    // MARK: - Sync (foreground)

    func syncEntitlement() async {
        do {
            let info = try await Purchases.shared.customerInfo(fetchPolicy: .cachedOrFetched)
            updateState(from: info)
        } catch {
            print("⚠️ RC entitlement sync failed — keeping cached state: \(error)")
        }
    }

    // MARK: - Sync (cold launch — cache only)

    func syncEntitlementCached() async {
        do {
            let info = try await Purchases.shared.customerInfo(fetchPolicy: .fromCacheOnly)
            updateState(from: info)
        } catch {
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

    // MARK: - Purchase

    func purchase(package: Package) async -> Bool {
        isPurchasing = true
        purchaseError = nil
        do {
            let (_, info, cancelled) = try await Purchases.shared.purchase(package: package)
            isPurchasing = false
            if !cancelled { updateState(from: info) }
            return !cancelled
        } catch {
            isPurchasing = false
            purchaseError = error.localizedDescription
            return false
        }
    }

    // MARK: - Restore

    @discardableResult
    func restorePurchases() async -> Bool {
        isPurchasing = true
        purchaseError = nil
        do {
            let info = try await Purchases.shared.restorePurchases()
            updateState(from: info)
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
