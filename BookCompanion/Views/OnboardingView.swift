//
//  OnboardingView.swift
//  BookCompanion
//
//  Redesigned: single-screen, no-scroll onboarding.
//  Compact feature pills, mini chat preview.
//  No AI references. Fits iPhone SE without scrolling.
//  Guest mode lives on SignInView only — not here.
//

import SwiftUI

// MARK: - Entry Point

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    let onComplete: () -> Void

    var body: some View {
        OnboardingSingleScreen {
            AnalyticsManager.shared.track(event: "onboarding_completed")
            withAnimation {
                hasCompletedOnboarding = true
                onComplete()
            }
        }
        .onAppear {
            AnalyticsManager.shared.track(event: "onboarding_started")
        }
    }
}

// MARK: - Single Screen (no scroll)

struct OnboardingSingleScreen: View {
    let onComplete: () -> Void

    @State private var phase: Int = 0
    @State private var visibleBubbles = 0
    @State private var shimmer = false
    @State private var sequenceTask: Task<Void, Never>? = nil

    @Environment(\.colorScheme) private var colorScheme

    private let chatBubbles: [(isUser: Bool, text: String)] = [
        (false, "For you, a thousand times over."),
        (true,  "Did you know Amir was there that day?"),
    ]

    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.height < 700

            ZStack {
                // ── Background ─────────────────────────────────────────
                Color(.systemBackground).ignoresSafeArea()

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Colors.primary.opacity(colorScheme == .dark ? 0.18 : 0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 220
                        )
                    )
                    .frame(width: 440, height: 440)
                    .position(x: geo.size.width * 0.85, y: -20)
                    .allowsHitTesting(false)

                // ── Content — single VStack, no scroll ─────────────────
                VStack(spacing: 0) {

                    Spacer(minLength: isCompact ? 16 : 36)

                    // ── 1. Headline ─────────────────────────────────────
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Read deeper.")
                            .font(.system(size: isCompact ? 32 : 36, weight: .black, design: .serif))
                            .foregroundColor(.primary)
                        Text("Never get lost.")
                            .font(.system(size: isCompact ? 32 : 36, weight: .black, design: .serif))
                            .foregroundStyle(Theme.Colors.brandGradientDiagonal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .opacity(phase >= 1 ? 1 : 0)
                    .offset(y: phase >= 1 ? 0 : 18)
                    .animation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.05), value: phase)

                    Text("Spoiler-safe summaries, character guides\nand live chats — for every book you read.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                        .padding(.horizontal, 28)
                        .padding(.top, 10)
                        .opacity(phase >= 1 ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.15), value: phase)

                    // ── 2. Feature pills — compact horizontal row ──────
                    HStack(spacing: 8) {
                        OnboardingFeaturePill(icon: "books.vertical.fill", label: "Books")
                        OnboardingFeaturePill(icon: "sparkles", label: "Summaries")
                        OnboardingFeaturePill(icon: "bubble.left.and.bubble.right.fill", label: "Chat")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, isCompact ? 16 : 22)
                    .opacity(phase >= 2 ? 1 : 0)
                    .offset(y: phase >= 2 ? 0 : 12)
                    .animation(.spring(response: 0.5, dampingFraction: 0.78), value: phase)

                    // ── 3. Mini chat preview ────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Theme.Colors.brandGradientDiagonal)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Text("H")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Hassan")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("The Kite Runner")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("Ch. 15")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Theme.Colors.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.secondary.opacity(0.12))
                                .cornerRadius(Theme.CornerRadius.xs)
                        }

                        Divider().opacity(0.3).padding(.vertical, 8)

                        VStack(spacing: 6) {
                            ForEach(
                                Array(chatBubbles.prefix(visibleBubbles).enumerated()),
                                id: \.offset
                            ) { _, bubble in
                                OnboardingChatBubble(isUser: bubble.isUser, text: bubble.text)
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .bottom).combined(with: .opacity),
                                            removal: .opacity
                                        )
                                    )
                            }
                        }
                        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: visibleBubbles)

                        if visibleBubbles < chatBubbles.count && phase >= 3 {
                            OnboardingTypingIndicator()
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(Theme.CornerRadius.xl)
                    .shadow(color: Theme.Colors.brandShadow.opacity(0.3), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    .padding(.top, isCompact ? 16 : 22)
                    .opacity(phase >= 3 ? 1 : 0)
                    .offset(y: phase >= 3 ? 0 : 14)
                    .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.06), value: phase)

                    Spacer(minLength: isCompact ? 12 : 20)

                    // ── 4. Gift tray + CTA ──────────────────────────────
                    VStack(spacing: 12) {

                        // Voucher tray
                        VStack(spacing: 8) {
                            Text("YOUR MONTHLY STARTER PACK")
                                .font(.system(size: 9, weight: .bold))
                                .kerning(1.1)
                                .foregroundColor(Theme.Colors.secondary)

                            HStack(spacing: 0) {
                                Spacer()
                                OnboardingGiftStat(number: "5", label: "Summaries")
                                Spacer()
                                Rectangle()
                                    .fill(Color(.separator))
                                    .frame(width: 0.5, height: 28)
                                Spacer()
                                OnboardingGiftStat(number: "5", label: "Characters")
                                Spacer()
                                Rectangle()
                                    .fill(Color(.separator))
                                    .frame(width: 0.5, height: 28)
                                Spacer()
                                OnboardingGiftStat(number: "5", label: "Chats")
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(Theme.CornerRadius.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                                    .stroke(
                                        shimmer
                                        ? Theme.Colors.brandGradient
                                        : LinearGradient(
                                            colors: [
                                                Theme.Colors.primary.opacity(0.25),
                                                Theme.Colors.secondary.opacity(0.25)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: shimmer ? 1.2 : 0.5
                                    )
                                    .animation(
                                        .easeInOut(duration: 0.6)
                                            .repeatCount(3, autoreverses: true),
                                        value: shimmer
                                    )
                            )
                        }

                        // CTA
                        Button {
                            HapticManager.success()
                            onComplete()
                        } label: {
                            Text("Start Reading — It's Free")
                        }
                        .buttonStyle(BrandGradientButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, isCompact ? 24 : 36)
                    .opacity(phase >= 4 ? 1 : 0)
                    .offset(y: phase >= 4 ? 0 : 12)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.04), value: phase)
                }
            }
        }
        .onAppear { startSequence() }
        .onDisappear { sequenceTask?.cancel() }
    }

    // MARK: - Animation sequence

    private func startSequence() {
        sequenceTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { phase = 1 }

            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { phase = 2 }

            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { phase = 3 }

            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation { visibleBubbles = 1 }
                HapticManager.lightImpact()
            }

            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation { visibleBubbles = 2 }
                HapticManager.lightImpact()
            }

            // CTA reveal
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation { phase = 4 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shimmer = true
                }
            }
        }
    }
}

// MARK: - Feature Pill (compact)

struct OnboardingFeaturePill: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Theme.Colors.brandGradientDiagonal)
                .cornerRadius(6)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Theme.CornerRadius.lg)
    }
}

// MARK: - Gift Stat Cell

struct OnboardingGiftStat: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(number)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(Theme.Colors.brandGradientDiagonal)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Chat Bubble

struct OnboardingChatBubble: View {
    let isUser: Bool
    let text: String

    var body: some View {
        HStack(alignment: .bottom) {
            if isUser { Spacer(minLength: 40) }
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(isUser ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    isUser
                    ? AnyView(Theme.Colors.brandGradient)
                    : AnyView(Color(.systemGray5))
                )
                .cornerRadius(14)
                .cornerRadius(isUser ? 4 : 14, corners: isUser ? .topRight : .bottomLeft)
            if !isUser { Spacer(minLength: 40) }
        }
    }
}

// MARK: - Typing Indicator

struct OnboardingTypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.secondary.opacity(0.55))
                    .frame(width: 5, height: 5)
                    .scaleEffect(animating ? (i == 1 ? 1.4 : 0.8) : (i == 1 ? 0.8 : 1.2))
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(.systemGray5))
        .cornerRadius(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { animating = true }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
