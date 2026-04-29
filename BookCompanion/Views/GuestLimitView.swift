//
//  GuestLimitView.swift
//  BookCompanion
//
//  Shown when a guest hits their quota for any feature.
//  Never shows the paywall — guests must create a free account first.
//  Clean, focused, single CTA: Create Free Account.
//

import SwiftUI

struct GuestLimitView: View {
    let featureType: GuestFeatureType
    let onCreateAccount: () -> Void
    let onDismiss: () -> Void

    enum GuestFeatureType {
        case summary
        case character
        case chat

        var icon: String {
            switch self {
            case .summary:   return "text.book.closed.fill"
            case .character: return "sparkles"
            case .chat:      return "bubble.left.and.bubble.right.fill"
            }
        }

        var title: String {
            switch self {
            case .summary:   return "You've used your free summary"
            case .character: return "You've used your free character analysis"
            case .chat:      return "You've used your free chat messages"
            }
        }

        var subtitle: String {
            switch self {
            case .summary:   return "Create a free account to get 5 summaries every month."
            case .character: return "Create a free account to get 5 character analyses every month."
            case .chat:      return "Create a free account to get 5 character chats every month."
            }
        }

        var benefit: String {
            switch self {
            case .summary:   return "5 summaries · every month · free"
            case .character: return "5 character analyses · every month · free"
            case .chat:      return "5 character chats · every month · free"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Close button ─────────────────────────────────────────────
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 16)
                .padding(.trailing, 20)
            }

            Spacer()

            // ── Icon ─────────────────────────────────────────────────────
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.10))
                    .frame(width: 88, height: 88)
                Image(systemName: featureType.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primary)
            }
            .padding(.bottom, 24)

            // ── Headline ─────────────────────────────────────────────────
            Text(featureType.title)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 10)

            Text(featureType.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.bottom, 32)

            // ── What you get ─────────────────────────────────────────────
            VStack(spacing: 12) {
                benefitRow(icon: "text.book.closed.fill", text: "5 spoiler-free summaries/month")
                benefitRow(icon: "sparkles",              text: "5 character analyses/month")
                benefitRow(icon: "bubble.left.and.bubble.right.fill", text: "5 character chats/month")
                benefitRow(icon: "arrow.clockwise",       text: "Resets every month · always free")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 36)

            // ── CTA ───────────────────────────────────────────────────────
            Button(action: onCreateAccount) {
                Text("Create Free Account")
            }
            .buttonStyle(BrandGradientButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // ── Already have account ──────────────────────────────────────
            Button(action: onCreateAccount) {
                Text("Already have an account? Sign in")
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.primary)
            }
            .padding(.bottom, 8)

            Spacer()
        }
        .background(Color(.systemBackground))
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.secondary)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.Colors.secondary)
        }
    }
}

#Preview {
    GuestLimitView(
        featureType: .summary,
        onCreateAccount: {},
        onDismiss: {}
    )
}
