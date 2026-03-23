//
//  OnboardingView.swift
//  BookCompanion
//
//  Redesigned 2026: single-screen cinematic onboarding.
//  Light/dark adaptive. Task-based sequence (auto-cancels on dismiss).
//  Haptic on each chat bubble. Shimmer on gift tray. SE-safe chevron hint.
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

// MARK: - Single Screen

struct OnboardingSingleScreen: View {
    let onComplete: () -> Void

    @State private var phase: Int = 0
    @State private var visibleBubbles = 0
    @State private var shimmer = false
    @State private var chevronBounce = false
    @State private var hasScrolled = false
    @State private var sequenceTask: Task<Void, Never>? = nil

    @Environment(\.colorScheme) private var colorScheme

    private let features: [(icon: String, label: String, sub: String)] = [
        ("books.vertical.fill",
         "Every Book Type",
         "Fiction · Biography · Autobiography"),
        ("sparkles",
         "Spoiler-Free Summaries",
         "AI recaps tailored to your exact chapter"),
        ("bubble.left.and.bubble.right.fill",
         "Deep Character Chat",
         "Context-aware dialogue with any protagonist"),
    ]

    private let chatBubbles: [(isUser: Bool, text: String)] = [
        (false, "For you, a thousand times over."),
        (true,  "Did you know Amir was there that day?"),
        (false, "I saw him. But love doesn't vanish because of one terrible day."),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {

                // ── Background ─────────────────────────────────────────
                Color(.systemBackground).ignoresSafeArea()

                // Indigo glow — top right
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Colors.primary.opacity(colorScheme == .dark ? 0.20 : 0.09),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 260
                        )
                    )
                    .frame(width: 520, height: 520)
                    .position(x: geo.size.width * 0.88, y: -40)
                    .allowsHitTesting(false)

                // Teal glow — bottom left
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Colors.secondary.opacity(colorScheme == .dark ? 0.16 : 0.07),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .position(x: geo.size.width * 0.12, y: geo.size.height + 60)
                    .allowsHitTesting(false)

                // ── Scroll content ──────────────────────────────────────
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── 1. Headline ─────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Read deeper.")
                                .font(.system(size: 44, weight: .black, design: .serif))
                                .foregroundColor(.primary)
                            Text("Never get lost.")
                                .font(.system(size: 44, weight: .black, design: .serif))
                                .foregroundStyle(Theme.Colors.brandGradientDiagonal)
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, max(60, geo.size.height * 0.09))
                        .opacity(phase >= 1 ? 1 : 0)
                        .offset(y: phase >= 1 ? 0 : 22)
                        .animation(.spring(response: 0.65, dampingFraction: 0.82).delay(0.05), value: phase)

                        Text("Spoiler-safe summaries, character guides\nand live chats — powered by AI.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineSpacing(5)
                            .padding(.horizontal, 28)
                            .padding(.top, 14)
                            .opacity(phase >= 1 ? 1 : 0)
                            .offset(y: phase >= 1 ? 0 : 14)
                            .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.18), value: phase)

                        // ── 2. Feature rows ─────────────────────────────
                        VStack(spacing: 10) {
                            ForEach(Array(features.enumerated()), id: \.offset) { i, feature in
                                OnboardingFeatureRow(
                                    icon: feature.icon,
                                    label: feature.label,
                                    sub: feature.sub
                                )
                                .opacity(phase >= 2 ? 1 : 0)
                                .offset(x: phase >= 2 ? 0 : -28)
                                .animation(
                                    .spring(response: 0.52, dampingFraction: 0.78)
                                        .delay(Double(i) * 0.09),
                                    value: phase
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)

                        // ── 3. Live chat preview ────────────────────────
                        VStack(alignment: .leading, spacing: 0) {

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Theme.Colors.secondary)
                                    .frame(width: 6, height: 6)
                                Text("Live preview")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.Colors.secondary)
                                    .textCase(.uppercase)
                                    .kerning(0.9)
                            }
                            .padding(.bottom, 12)
                            .opacity(phase >= 3 ? 1 : 0)
                            .animation(.easeOut(duration: 0.3).delay(0.05), value: phase)

                            VStack(alignment: .leading, spacing: 12) {

                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Theme.Colors.brandGradientDiagonal)
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Text("H")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("Hassan")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("Character · The Kite Runner")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("Ch. 15")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Theme.Colors.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Theme.Colors.secondary.opacity(0.12))
                                        .cornerRadius(Theme.CornerRadius.sm)
                                }

                                Divider().opacity(0.4)

                                VStack(spacing: 8) {
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
                            .padding(16)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(Theme.CornerRadius.xl)
                            .shadow(color: Theme.Colors.brandShadow.opacity(0.4), radius: 14, x: 0, y: 5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .opacity(phase >= 3 ? 1 : 0)
                        .offset(y: phase >= 3 ? 0 : 18)
                        .animation(.spring(response: 0.58, dampingFraction: 0.82).delay(0.08), value: phase)

                        // ── 4. Gift tray + CTA ──────────────────────────
                        VStack(spacing: 14) {

                            // Voucher tray with shimmer border on reveal
                            VStack(spacing: 10) {
                                Text("YOUR MONTHLY STARTER PACK")
                                    .font(.system(size: 10, weight: .bold))
                                    .kerning(1.2)
                                    .foregroundColor(Theme.Colors.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                HStack(spacing: 0) {
                                    Spacer()
                                    OnboardingGiftStat(number: "5", label: "Chapter\nSummaries")
                                    Spacer()
                                    Rectangle()
                                        .fill(Color(.separator))
                                        .frame(width: 0.5, height: 32)
                                    Spacer()
                                    OnboardingGiftStat(number: "5", label: "Character\nAnalysis")
                                    Spacer()
                                    Rectangle()
                                        .fill(Color(.separator))
                                        .frame(width: 0.5, height: 32)
                                    Spacer()
                                    OnboardingGiftStat(number: "5", label: "Character\nChats")
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(Theme.CornerRadius.lg)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                                        .stroke(
                                            // Shimmer: alternate between gradient and faint on reveal
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
                        .padding(.top, 28)
                        .padding(.bottom, max(40, geo.size.height * 0.06))
                        .opacity(phase >= 4 ? 1 : 0)
                        .offset(y: phase >= 4 ? 0 : 14)
                        .animation(.spring(response: 0.52, dampingFraction: 0.85).delay(0.04), value: phase)
                    }
                    // Track scroll to hide chevron hint
                    .background(
                        GeometryReader { scrollGeo in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetKey.self,
                                    value: scrollGeo.frame(in: .named("scroll")).minY
                                )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetKey.self) { offset in
                    if offset < -20 { hasScrolled = true }
                }

                // ── Scroll hint chevron (SE / large text safety) ────────
                if phase >= 4 && !hasScrolled {
                    VStack(spacing: 0) {
                        // Fade gradient
                        LinearGradient(
                            colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 40)
                        .allowsHitTesting(false)

                        // Bouncing chevron
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.Colors.brandGradient)
                            .padding(.bottom, 12)
                            .offset(y: chevronBounce ? 4 : 0)
                            .animation(
                                .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                                value: chevronBounce
                            )
                    }
                    .transition(.opacity)
                }
            }
        }
        .onAppear { startSequence() }
        .onDisappear { sequenceTask?.cancel() }
    }

    // MARK: - Task-based sequence (auto-cancels on dismiss)

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

            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation { visibleBubbles = 1 }
                HapticManager.lightImpact()
            }

            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation { visibleBubbles = 2 }
                HapticManager.lightImpact()
            }

            // CTA at ~2.5s
            try? await Task.sleep(nanoseconds: 550_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation { phase = 4 }
                // Trigger shimmer on gift tray
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shimmer = true
                }
                // Start chevron bounce
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    chevronBounce = true
                }
            }

            try? await Task.sleep(nanoseconds: 650_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation { visibleBubbles = 3 }
                HapticManager.lightImpact()
            }
        }
    }
}

// MARK: - Gift Stat Cell

struct OnboardingGiftStat: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(number)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(Theme.Colors.brandGradientDiagonal)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}

// MARK: - Feature Row

struct OnboardingFeatureRow: View {
    let icon: String
    let label: String
    let sub: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.brandGradientDiagonal)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text(sub)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Theme.CornerRadius.xl)
    }
}

// MARK: - Chat Bubble

struct OnboardingChatBubble: View {
    let isUser: Bool
    let text: String

    var body: some View {
        HStack(alignment: .bottom) {
            if isUser { Spacer(minLength: 44) }
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(isUser ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    isUser
                    ? AnyView(Theme.Colors.brandGradient)
                    : AnyView(Color(.systemGray5))
                )
                .cornerRadius(16)
                .cornerRadius(isUser ? 4 : 16, corners: isUser ? .topRight : .bottomLeft)
            if !isUser { Spacer(minLength: 44) }
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
                    .frame(width: 6, height: 6)
                    .scaleEffect(animating ? (i == 1 ? 1.4 : 0.8) : (i == 1 ? 0.8 : 1.2))
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color(.systemGray5))
        .cornerRadius(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { animating = true }
    }
}

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
