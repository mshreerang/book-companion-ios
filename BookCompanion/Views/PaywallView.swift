//
//  PaywallView.swift
//  BookCompanion
//
//  Created by Shree on 28/02/2026.
//  Updated: removed stale "(March)" date from Character Chat feature,
//           replaced hardcoded blue/purple/green/orange/teal icon colours
//           with Theme brand colours, CTA gradient uses Theme.
//           Fixed legal doc URLs to use vivanlabs.com domain.
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreManager

    let triggerReason: String

    @State private var selectedPlan: PlanType = .annual
    @State private var isLoading = true
    @State private var showSuccess = false

    enum PlanType { case monthly, annual }

    init(triggerReason: String = "") {
        self.triggerReason = triggerReason
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    Divider().padding(.vertical, 8)
                    featuresSection
                    Divider().padding(.vertical, 8)
                    pricingToggle
                    ctaSection
                    legalFooter
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
            .task { await loadOfferings() }
            .overlay {
                if showSuccess {
                    ProSuccessOverlay(isFoundingMember: store.isFoundingMember)
                        .transition(.opacity)
                        .animation(.easeIn(duration: 0.3), value: showSuccess)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 52))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .orange.opacity(0.4), radius: 8)
                .padding(.top, 24)

            Text("BookCompanion Pro")
                .font(.title.bold())

            Text(triggerReason.isEmpty
                 ? "Unlimited reading insights, powered by AI"
                 : triggerReason)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Features
    //
    // All feature icon colours now use Theme brand colours for consistency.
    // The crown/gold colours are intentionally kept for the header — those
    // encode "premium" semantically. Feature row icons use brand indigo/teal.

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            PaywallFeatureRow(
                icon: "infinity",
                color: Theme.Colors.primary,
                text: "Unlimited Summaries",
                sub: "Any chapter, any book, anytime"
            )
            PaywallFeatureRow(
                icon: "sparkles",
                color: Theme.Colors.secondary,
                text: "Unlimited Character Analysis",
                sub: "Deep dive into every character"
            )
            PaywallFeatureRow(
                icon: "bubble.left.and.bubble.right.fill",
                color: Theme.Colors.primary,
                text: "Chat with Characters",
                sub: "Chat with characters — spoiler-safe"
            )
            PaywallFeatureRow(
                icon: "square.and.arrow.up",
                color: Theme.Colors.secondary,
                text: "Export & Share",
                sub: "Save your reading insights"
            )
            PaywallFeatureRow(
                icon: "person.3.fill",
                color: Theme.Colors.primary,
                text: "Family Sharing Included",
                sub: "Share with up to 5 family members"
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Pricing Toggle

    private var pricingToggle: some View {
        VStack(spacing: 8) {
            if isLoading {
                ProgressView().frame(height: 52)
            } else {
                HStack(spacing: 0) {
                    planButton(.annual,  label: annualLabel)
                    planButton(.monthly, label: monthlyLabel)
                }
                .background(Color(.systemGray6))
                .cornerRadius(Theme.CornerRadius.lg)
                .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Pricing Labels

    private var annualPackage:   Package? { store.offerings?.current?.annual }
    private var monthlyPackage:  Package? { store.offerings?.current?.monthly }
    private var selectedPackage: Package? { selectedPlan == .annual ? annualPackage : monthlyPackage }

    private var annualLabel: String {
        guard let p = annualPackage else { return "Annual" }
        if let intro = p.storeProduct.introductoryDiscount, intro.price > 0 {
            return "Annual · \(intro.localizedPriceString) first year"
        }
        return "Annual · \(p.storeProduct.localizedPriceString) (Save 33%)"
    }

    private var monthlyLabel: String {
        guard let p = monthlyPackage else { return "Monthly" }
        if let intro = p.storeProduct.introductoryDiscount, intro.price > 0 {
            return "Monthly · \(intro.localizedPriceString)/mo for 3 months"
        }
        return "Monthly · \(p.storeProduct.localizedPriceString)"
    }

    private var selectedPriceSubtitle: String? {
        switch selectedPlan {
        case .annual:
            guard let p = annualPackage else { return nil }
            if let intro = p.storeProduct.introductoryDiscount, intro.price > 0 {
                return "\(intro.localizedPriceString) for first year, then \(p.storeProduct.localizedPriceString)/year"
            }
            return "\(p.storeProduct.localizedPriceString)/year, billed annually"
        case .monthly:
            guard let p = monthlyPackage else { return nil }
            if let intro = p.storeProduct.introductoryDiscount, intro.price > 0 {
                return "\(intro.localizedPriceString)/month for 3 months, then \(p.storeProduct.localizedPriceString)/month"
            }
            return "\(p.storeProduct.localizedPriceString)/month"
        }
    }

    private var ctaButtonLabel: String {
        guard let pkg = selectedPackage else { return "Start Free Trial" }
        let price  = pkg.storeProduct.localizedPriceString
        let period = selectedPlan == .annual ? "year" : "month"
        if let intro = pkg.storeProduct.introductoryDiscount {
            if intro.price == 0 {
                let days = intro.subscriptionPeriod.value
                return "Try Free for \(days) Days, then \(price)/\(period)"
            } else {
                if selectedPlan == .annual {
                    return "Start 1 Year at \(intro.localizedPriceString), then \(price)/year"
                } else {
                    return "Start at \(intro.localizedPriceString)/mo, then \(price)/month"
                }
            }
        }
        return "Subscribe for \(price)/\(period)"
    }

    private func planButton(_ plan: PlanType, label: String) -> some View {
        ZStack(alignment: .topTrailing) {
            Button { selectedPlan = plan } label: {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(selectedPlan == plan ? .semibold : .regular)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .background(selectedPlan == plan ? Color(.systemBackground) : Color.clear)
                    .cornerRadius(10)
                    .padding(2)
            }
            .foregroundStyle(selectedPlan == plan ? Color.primary : Color.secondary)

            if plan == .annual {
                let hasIntro = annualPackage?.storeProduct.introductoryDiscount != nil
                Text(hasIntro ? "Founding Offer" : "Best Value")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(Theme.CornerRadius.xs)
                    .offset(x: -4, y: 4)
            }
        }
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 8) {
            Button {
                Task { await handlePurchase() }
            } label: {
                Group {
                    if store.isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(ctaButtonLabel)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .background(Theme.Colors.brandGradient)
                .cornerRadius(Theme.CornerRadius.xl)
            }
            .disabled(store.isPurchasing || selectedPackage == nil)
            .shadow(color: Theme.Colors.brandShadow, radius: 10, x: 0, y: 5)
            .padding(.horizontal, 24)

            if let err = store.purchaseError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
            }

            Button("Restore Purchases") {
                Task {
                    await store.restorePurchases()
                    // Check isPro directly after restore — don't trust the return value
                    // since sandbox users may have had previous subscriptions
                    if store.isPro {
                        withAnimation { showSuccess = true }
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        dismiss()
                    } else {
                        store.purchaseError = "No active subscription found to restore."
                    }
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Legal Footer

    private var legalFooter: some View {
        VStack(spacing: 10) {
            if let subtitle = selectedPriceSubtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .fontWeight(.medium)
            }

            Text("Payment will be charged to your Apple ID account at the confirmation of purchase. Subscription automatically renews unless it is cancelled at least 24 hours before the end of the current period. You can manage and cancel your subscriptions by going to your App Store account settings after purchase.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Privacy Policy",
                     destination: URL(string: "https://mshreerang.github.io/book-companion-docs/privacy-policy.html")!)
                Text("·").foregroundStyle(.secondary)
                Link("Terms of Use",
                     destination: URL(string: "https://mshreerang.github.io/book-companion-docs/terms-of-use.html")!)
            }
            .font(.caption2)
            .foregroundStyle(Theme.Colors.primary)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    // MARK: - Actions

    private func loadOfferings() async {
        await store.loadOfferings()
        isLoading = false
    }

    private func handlePurchase() async {
        guard let pkg = selectedPackage else { return }
        let success = await store.purchase(package: pkg)
        if success {
            withAnimation { showSuccess = true }
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            dismiss()
        }
    }
}

// MARK: - Feature Row

struct PaywallFeatureRow: View {
    let icon: String
    let color: Color
    let text: String
    let sub: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(sub)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.Colors.secondary)
        }
    }
}

// MARK: - Pro Success Overlay

struct ProSuccessOverlay: View {
    let isFoundingMember: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .orange.opacity(0.6), radius: 20)

                VStack(spacing: 8) {
                    Text(isFoundingMember ? "Welcome, Founding Member!" : "Welcome to Pro!")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text("Unlimited summaries & character\nanalysis — unlocked.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }

                if isFoundingMember {
                    Label("Founding Member", systemImage: "star.fill")
                        .font(.footnote.bold())
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(20)
                }
            }
            .padding(40)
        }
    }
}

#Preview {
    PaywallView(triggerReason: "You've used all 5 free summaries this month.")
        .environmentObject(StoreManager.shared)
}
