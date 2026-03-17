//
//  TransparencyOnboardingView.swift
//  BookCompanion
//
//  Created by Shree on 01/03/2026.
//  Updated: unified section icon colour (brand indigo throughout),
//           replaced gmail support address with custom domain,
//           updated brand colours to indigo/teal.
//

import SwiftUI
import Combine

// MARK: - Transparency Onboarding View

struct TransparencyOnboardingView: View {

    var onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // Header
                VStack(spacing: 12) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Theme.Colors.brandGradientDiagonal)
                        .padding(.top, 48)

                    Text("Book Companion")
                        .font(.system(size: 28, weight: .bold))

                    Text("Here's the stuff that actually matters")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)

                // Sections
                // All icons use the same muted brand-indigo colour —
                // colour encodes meaning, not structure.
                VStack(spacing: 16) {
                    TransparencySection(
                        icon: "wand.and.stars",
                        title: "The Service",
                        items: [
                            TransparencyItem(
                                label: "What it is",
                                detail: "An AI reading assistant for summaries and character analysis."
                            ),
                            TransparencyItem(
                                label: "The AI",
                                detail: "Powered by Anthropic (Claude). It can make mistakes — use it for personal insight, not as a perfect factual record."
                            ),
                            TransparencyItem(
                                label: "Ownership",
                                detail: "You own your notes and reading data. We own the app and its design."
                            ),
                        ]
                    )

                    TransparencySection(
                        icon: "creditcard.fill",
                        title: "Subscription & Usage",
                        items: [
                            TransparencyItem(
                                label: "Free Tier",
                                detail: "5 AI summaries per month. No credit card needed."
                            ),
                            TransparencyItem(
                                label: "Pro Tier",
                                detail: "Unlimited access, subject to a fair-use cap of 200 summaries/month to keep the service running well for everyone."
                            ),
                            TransparencyItem(
                                label: "Payments",
                                detail: "Handled securely through Apple. We never see your credit card details."
                            ),
                        ]
                    )

                    TransparencySection(
                        icon: "lock.shield.fill",
                        title: "Privacy & Data",
                        items: [
                            TransparencyItem(
                                label: "No selling",
                                detail: "We never sell your personal data. Period."
                            ),
                            TransparencyItem(
                                label: "Sign-In",
                                detail: "We use Sign in with Apple for maximum privacy. Apple may provide a relay email — that's fine with us."
                            ),
                            TransparencyItem(
                                label: "AI processing",
                                detail: "We send book titles and chapter text to Anthropic to generate summaries. We never send your name, email, or Apple ID to them."
                            ),
                            TransparencyItem(
                                label: "Analytics",
                                detail: "We use PostHog and Sentry to find bugs and understand which features you use most. This data is pseudonymous and never sold."
                            ),
                        ]
                    )

                    TransparencySection(
                        icon: "person.badge.shield.checkmark.fill",
                        title: "Your Rights",
                        items: [
                            TransparencyItem(
                                label: "Jurisdiction",
                                detail: "These terms are governed by the laws of England and Wales."
                            ),
                            TransparencyItem(
                                label: "Account deletion",
                                // Updated: custom domain email replaces personal Gmail
                                detail: "Email support@bookcompanion.app at any time to delete your account and all associated data."
                            ),
                            TransparencyItem(
                                label: "UK GDPR",
                                detail: "If you're in the UK or EU, you have rights to access, correct, and delete your data. Just ask."
                            ),
                        ]
                    )
                }
                .padding(.horizontal, 16)

                // Legal links
                VStack(spacing: 8) {
                    Text("The full legal details are in our")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        Link("Privacy Policy",
                             destination: URL(string: "https://mshreerang.github.io/book-companion-ios/privacy-policy.html")!)
                            .font(.footnote)
                            .foregroundStyle(Theme.Colors.primary)

                        Text("·")
                            .foregroundStyle(.secondary)
                            .font(.footnote)

                        Link("Terms of Use",
                             destination: URL(string: "https://mshreerang.github.io/book-companion-ios/terms-of-use.html")!)
                            .font(.footnote)
                            .foregroundStyle(Theme.Colors.primary)
                    }
                }
                .padding(.top, 28)
                .padding(.bottom, 16)

                // CTA
                Button(action: onContinue) {
                    Text("Got it — Let's Go")
                }
                .buttonStyle(BrandGradientButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Supporting Types

struct TransparencyItem {
    let label: String
    let detail: String
}

// MARK: - Section Card

struct TransparencySection: View {
    let icon: String
    let title: String
    let items: [TransparencyItem]

    // iconColor removed — all icons now use the same brand-indigo tint
    // so the section chrome is visually consistent throughout.
    private let iconColor = Theme.Colors.primary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Section header
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 16)

            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.3)

                    Text(item.detail)
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if index < items.count - 1 {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xl))
    }
}

// MARK: - Preview

#Preview {
    TransparencyOnboardingView(onContinue: {})
}
