//
//  PaywallView.swift
//  BookCompanion
//
//  Updated v1.3 — Option A paywall with top-up first, Pro second.
//  Top-up: 5 summaries + 5 character analyses + 10 chat messages — £0.99
//  Credits never expire and never reset on the 1st of the month.
//
//  Credit counts are read directly from StoreManager (fetched live when
//  the view appears) — no need to pass them via init parameters.
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreManager

    let triggerReason: String

    @State private var selectedPlan: PlanType = .annual
    @State private var isLoadingOfferings = true
    @State private var showTopupSuccess = false
    @State private var showProSuccess = false

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
                    topupSection
                    dividerOr
                    proSection
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
            .task {
                await store.loadOfferings()
                await store.loadTopupProduct()
                await store.fetchTopupCredits()
                isLoadingOfferings = false
            }
            .overlay {
                if showTopupSuccess {
                    TopupSuccessOverlay()
                        .transition(.opacity)
                        .animation(.easeIn(duration: 0.3), value: showTopupSuccess)
                }
                if showProSuccess {
                    ProSuccessOverlay(isFoundingMember: store.isFoundingMember)
                        .transition(.opacity)
                        .animation(.easeIn(duration: 0.3), value: showProSuccess)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.brandGradient)
                .padding(.top, 24)

            Text(triggerReason.isEmpty
                 ? "You've used all your credits"
                 : triggerReason)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text("Your next summary is waiting. Unlock it now.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Top-Up Section (shown first — primary CTA)

    private var topupSection: some View {
        VStack(spacing: 12) {
            // What you get
            VStack(spacing: 0) {
                topupRow(icon: "text.book.closed.fill",
                         color: Theme.Colors.primary,
                         label: "5 Summaries",
                         creditsRemaining: store.topupSummaryCredits)
                Divider().padding(.leading, 44)
                topupRow(icon: "sparkles",
                         color: Theme.Colors.secondary,
                         label: "5 Character Analyses",
                         creditsRemaining: store.topupCharacterCredits)
                Divider().padding(.leading, 44)
                topupRow(icon: "bubble.left.and.bubble.right.fill",
                         color: Theme.Colors.primary,
                         label: "10 Chat Messages",
                         creditsRemaining: store.topupChatCredits)
            }
            .background(Color(.systemBackground))
            .cornerRadius(Theme.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .stroke(Color(.systemGray5), lineWidth: 0.5)
            )
            .padding(.horizontal, 24)

            // Credits never expire note
            Label("Credits never expire — use them any time", systemImage: "infinity")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Top-up CTA button
            Button {
                Task { await handleTopupPurchase() }
            } label: {
                Group {
                    if store.isTopupPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        HStack {
                            Text("Get More Credits")
                                .font(.system(size: 17, weight: .semibold))
                            Spacer()
                            Text(topupPriceLabel)
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.Colors.brandGradient)
                .cornerRadius(Theme.CornerRadius.xl)
            }
            .disabled(store.isTopupPurchasing || store.topupProduct == nil)
            .shadow(color: Theme.Colors.brandShadow, radius: 10, x: 0, y: 5)
            .padding(.horizontal, 24)

            if let err = store.purchaseError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 16)
    }

    private func topupRow(icon: String, color: Color, label: String, creditsRemaining: Int) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)
                .font(.body)
            Text(label)
                .font(.subheadline)
            Spacer()
            // Show current remaining credits if user already has some
            if creditsRemaining > 0 {
                Text("\(creditsRemaining) remaining")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.Colors.secondary.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.xs)
            } else {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(color.opacity(0.6))
                    .font(.body)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var topupPriceLabel: String {
        if let product = store.topupProduct {
            return product.localizedPriceString
        }
        return "£0.99"
    }

    // MARK: - Divider with "or go unlimited"

    private var dividerOr: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5)
            Text("or go unlimited")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize()
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 4)
    }

    // MARK: - Pro Section (secondary CTA)

    private var proSection: some View {
        VStack(spacing: 12) {
            // Crown + title
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("BookCompanion Pro")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 24)

            // Plan toggle
            if isLoadingOfferings {
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

            // Pro features — compact
            VStack(alignment: .leading, spacing: 8) {
                proFeatureRow("Unlimited summaries, characters & chat")
                proFeatureRow("Credits never run out again")
                proFeatureRow("Family Sharing included")
            }
            .padding(.horizontal, 24)

            // Pro CTA
            Button {
                Task { await handleProPurchase() }
            } label: {
                Group {
                    if store.isPurchasing {
                        ProgressView().tint(Theme.Colors.primary)
                    } else {
                        Text(ctaButtonLabel)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.Colors.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(Color(.systemBackground))
                .cornerRadius(Theme.CornerRadius.xl)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                        .stroke(Theme.Colors.primary, lineWidth: 1.5)
                )
            }
            .disabled(store.isPurchasing || selectedPackage == nil)
            .padding(.horizontal, 24)

            // Restore
            Button("Restore Purchases") {
                Task {
                    await store.restorePurchases()
                    if store.isPro {
                        withAnimation { showProSuccess = true }
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        dismiss()
                    } else {
                        store.purchaseError = "No active subscription found."
                    }
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
    }

    private func proFeatureRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.Colors.secondary)
                .font(.footnote)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
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

            Text("Payment charged to your Apple ID at confirmation. Subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in App Store settings.")
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
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Pricing Helpers

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
        guard let pkg = selectedPackage else { return "Subscribe to Pro" }
        let price  = pkg.storeProduct.localizedPriceString
        let period = selectedPlan == .annual ? "year" : "month"
        if let intro = pkg.storeProduct.introductoryDiscount {
            if intro.price == 0 {
                let days = intro.subscriptionPeriod.value
                return "Try Free for \(days) Days"
            } else {
                if selectedPlan == .annual {
                    return "Start 1 Year at \(intro.localizedPriceString)"
                } else {
                    return "Start at \(intro.localizedPriceString)/mo"
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

    // MARK: - Actions

    private func handleTopupPurchase() async {
        let success = await store.purchaseTopup()
        if success {
            withAnimation { showTopupSuccess = true }
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            showTopupSuccess = false
            dismiss()
        }
    }

    private func handleProPurchase() async {
        guard let pkg = selectedPackage else { return }
        let success = await store.purchase(package: pkg)
        if success {
            withAnimation { showProSuccess = true }
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            dismiss()
        }
    }
}

// MARK: - Top-Up Success Overlay

struct TopupSuccessOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Theme.Colors.brandGradient)

                VStack(spacing: 8) {
                    Text("Credits Added!")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text("5 summaries · 5 character analyses\n10 chat messages — ready to use.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }

                Label("Never expire", systemImage: "infinity")
                    .font(.footnote.bold())
                    .foregroundStyle(Theme.Colors.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.secondary.opacity(0.15))
                    .cornerRadius(20)
            }
            .padding(40)
        }
    }
}

// MARK: - Pro Success Overlay (unchanged)

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
                        .background(Color.yellow.opacity(0.25))
                        .cornerRadius(20)
                }
            }
            .padding(40)
        }
    }
}

// MARK: - Feature Row (kept for any other callers)

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

#Preview {
    PaywallView(triggerReason: "You've used all 5 free summaries this month.")
        .environmentObject(StoreManager.shared)
}
