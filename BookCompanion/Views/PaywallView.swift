//
//  PaywallView.swift
//  BookCompanion
//
//  Created by Shree on 28/02/2026.
//

import SwiftUI
import RevenueCat

// MARK: - PaywallView

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreManager

    let triggerReason: String

    @State private var selectedPlan: PlanType = .annual
    @State private var isLoading = true
    @State private var showSuccess = false

    enum PlanType { case monthly, annual }

    // Convenience init for quota-triggered presentation
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
                .foregroundStyle(LinearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing))
                .shadow(color: .orange.opacity(0.4), radius: 8)
                .padding(.top, 24)

            Text("BookCompanion Pro")
                .font(.title.bold())

            if !triggerReason.isEmpty {
                Text(triggerReason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                Text("Unlimited reading insights, powered by AI")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            PaywallFeatureRow(
                icon: "infinity",
                color: .blue,
                text: "Unlimited Summaries",
                sub: "Any chapter, any book, anytime")
            PaywallFeatureRow(
                icon: "person.2.fill",
                color: .purple,
                text: "Unlimited Character Analysis",
                sub: "Deep dive into every character")
            PaywallFeatureRow(
                icon: "bubble.left.fill",
                color: .green,
                text: "AI Character Chat",
                sub: "Chat with your book's characters (March)")
            PaywallFeatureRow(
                icon: "square.and.arrow.up",
                color: .orange,
                text: "Export & Share",
                sub: "Save your reading insights")
            // Family Sharing — zero cost, high value for families
            PaywallFeatureRow(
                icon: "person.3.fill",
                color: .teal,
                text: "Family Sharing Included",
                sub: "Share with up to 5 family members")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Pricing Toggle

    private var pricingToggle: some View {
        VStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .frame(height: 52)
            } else {
                HStack(spacing: 0) {
                    planButton(.annual,  label: annualLabel)
                    planButton(.monthly, label: monthlyLabel)
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Pricing Labels (introductory offer aware)
    // Always shows the price the user will ACTUALLY be charged at checkout.

    private var annualPackage: Package? {
        store.offerings?.current?.annual
    }
    private var monthlyPackage: Package? {
        store.offerings?.current?.monthly
    }
    private var selectedPackage: Package? {
        selectedPlan == .annual ? annualPackage : monthlyPackage
    }

    private var annualLabel: String {
        guard let p = annualPackage else { return "Annual" }
        if let intro = p.storeProduct.introductoryDiscount,
           intro.price > 0 {
            return "Annual · \(intro.localizedPriceString) first year"
        }
        return "Annual · \(p.storeProduct.localizedPriceString) (Save 33%)"
    }

    private var monthlyLabel: String {
        guard let p = monthlyPackage else { return "Monthly" }
        if let intro = p.storeProduct.introductoryDiscount,
           intro.price > 0 {
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

    // CTA label — explicitly states trial duration AND price after trial (Apple 3.1.2)
    private var ctaButtonLabel: String {
        guard let pkg = selectedPackage else { return "Start Free Trial" }
        let price = pkg.storeProduct.localizedPriceString
        let period = selectedPlan == .annual ? "year" : "month"
        if let intro = pkg.storeProduct.introductoryDiscount {
            if intro.price == 0 {
                // Free trial
                let days = intro.subscriptionPeriod.value
                return "Try Free for \(days) Days, then \(price)/\(period)"
            } else {
                // Paid intro offer
                if selectedPlan == .annual {
                    return "Start 1 Year at \(intro.localizedPriceString), then \(price)/year"
                } else {
                    return "Start at \(intro.localizedPriceString)/mo, then \(price)/month"
                }
            }
        }
        return "Subscribe for \(price)/\(period)"
    }

    // MARK: - Plan Button (with Best Value badge)

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

            // Best Value / Founding Offer badge — annual only
            if plan == .annual {
                let hasIntro = annualPackage?.storeProduct.introductoryDiscount != nil
                Text(hasIntro ? "Founding Offer" : "Best Value")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(4)
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
                .background(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing))
                .cornerRadius(14)
            }
            .disabled(store.isPurchasing || selectedPackage == nil)
            .padding(.horizontal, 24)

            if let err = store.purchaseError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
            }

            Button("Restore Purchases") {
                Task {
                    // A — Restoration UX: trigger same success overlay as purchase.
                    // User who reinstalls after paying must not be stuck on paywall.
                    let restored = await store.restorePurchases()
                    if restored {
                        withAnimation { showSuccess = true }
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        dismiss()
                    }
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Legal Footer (Apple Guideline 3.1.2 compliant)

    private var legalFooter: some View {
        VStack(spacing: 10) {

            // Price-after-trial clarity — shown when a package is selected
            if let subtitle = selectedPriceSubtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .fontWeight(.medium)
            }

            // Apple-required legal paragraph
            Text("Payment will be charged to your Apple ID account at the confirmation of purchase. Subscription automatically renews unless it is cancelled at least 24 hours before the end of the current period. You can manage and cancel your subscriptions by going to your App Store account settings after purchase.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Privacy Policy & Terms — must be tappable links, not plain text
            HStack(spacing: 16) {
                Link("Privacy Policy",
                     destination: URL(string: "https://mshreerang.github.io/book-companion-ios/privacy-policy.html")!)
                Text("·").foregroundStyle(.secondary)
                Link("Terms of Use",
                     destination: URL(string: "https://mshreerang.github.io/book-companion-ios/terms-of-use.html")!)
            }
            .font(.caption2)
            .foregroundStyle(.blue)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    // MARK: - Actions

    private func loadOfferings() async {
        await store.loadOfferings()
        isLoading = false
    }

    @State private var showSuccess_handlePurchase = false

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
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Pro Success Overlay
// Shown for 2.5s after successful purchase or restore before auto-dismissing.

struct ProSuccessOverlay: View {
    let isFoundingMember: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
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

// MARK: - Preview

#Preview {
    PaywallView(triggerReason: "You've used all 5 free summaries this month.")
        .environmentObject(StoreManager.shared)
}
