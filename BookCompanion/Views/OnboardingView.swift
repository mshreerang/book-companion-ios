//
//  OnboardingView.swift
//  BookCompanion
//
//  Created by Shree on 07/02/2026.
//  Updated: fixed triple-language subtitle bug, unified icon style,
//           added Skip button, removed disabled grey CTA on final slide,
//           updated brand colours to indigo/teal.
//

import SwiftUI

struct OnboardingView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    let onComplete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {

            // Background gradient — consistent across all 4 slides
            LinearGradient(
                colors: [
                    Theme.Colors.gradientStart.opacity(0.08),
                    Theme.Colors.gradientEnd.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TabView(selection: $currentPage) {

                // Page 1: Welcome
                OnboardingPageView(
                    systemImage: "book.closed.fill",
                    title: NSLocalizedString("onboarding_welcome_title",
                                            value: "Welcome to BookCompanion",
                                            comment: "Onboarding page 1 title"),
                    description: NSLocalizedString("onboarding_welcome_desc",
                                                   value: "Your AI reading assistant for complex books",
                                                   comment: "Onboarding page 1 description")
                )
                .tag(0)

                // Page 2: Smart Summaries
                OnboardingPageView(
                    systemImage: "text.document.fill",
                    title: NSLocalizedString("onboarding_summaries_title",
                                            value: "Smart Summaries",
                                            comment: "Onboarding page 2 title"),
                    description: NSLocalizedString("onboarding_summaries_desc",
                                                   value: "Get spoiler-free recaps and character guides",
                                                   comment: "Onboarding page 2 description")
                )
                .tag(1)

                // Page 3: Character Chat (live preview — no icon needed)
                OnboardingCharacterChatPageView()
                    .tag(2)

                // Page 4: Ready to Start
                OnboardingFinalPageView(onComplete: {
                    completeOnboarding()
                })
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Skip button — visible on pages 0–2 only
            if currentPage < 3 {
                Button("Skip") {
                    withAnimation {
                        currentPage = 3
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
                .padding(.top, 56)
                .padding(.trailing, 20)
                .transition(.opacity)
            }
        }
        .onAppear {
            AnalyticsManager.shared.track(event: "onboarding_started")
        }
    }

    private func completeOnboarding() {
        AnalyticsManager.shared.track(event: "onboarding_completed")
        withAnimation {
            hasCompletedOnboarding = true
            onComplete()
        }
    }
}

// MARK: - Generic Onboarding Page

struct OnboardingPageView: View {
    let systemImage: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon — unified style: indigo→teal diagonal gradient, same size on all slides
            Image(systemName: systemImage)
                .font(.system(size: 90))
                .foregroundStyle(Theme.Colors.brandGradientDiagonal)
                .shadow(color: Theme.Colors.brandShadow, radius: 20, x: 0, y: 10)
                .padding(.bottom, 36)

            VStack(spacing: 14) {
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)

                // Single localised string — no stacked translations
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Character Chat Page

struct OnboardingCharacterChatPageView: View {

    @State private var visibleBubbles = 0

    private let bubbles: [(isUser: Bool, text: String)] = [
        (false, "So… you've read this far. What is it you want to know?"),
        (true,  "Do you think Harry put his name in the Goblet?"),
        (false, "Absolutely not. I know Harry. He would never seek that kind of attention."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon — same style as other slides
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.Colors.brandGradientDiagonal)
                .shadow(color: Theme.Colors.brandShadow, radius: 20, x: 0, y: 10)
                .padding(.bottom, 28)

            VStack(spacing: 12) {
                Text("Talk to the Characters")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Ask them anything — they only know what you've read so far.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }

            // Mock chat preview
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Theme.Colors.brandGradient)
                        .frame(width: 26, height: 26)
                        .overlay(
                            Text("H")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                        )
                    Text("Hermione Granger · Ch. 33")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 4)

                ForEach(Array(bubbles.prefix(visibleBubbles).enumerated()), id: \.offset) { _, bubble in
                    MockChatBubble(isUser: bubble.isUser, text: bubble.text)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: visibleBubbles)

            Spacer()
            Spacer()
        }
        .padding()
        .onAppear { animateBubbles() }
    }

    private func animateBubbles() {
        visibleBubbles = 0
        for i in 0..<bubbles.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.1) {
                visibleBubbles = i + 1
            }
        }
    }
}

// Mock chat bubble — uses brand gradient for user messages
private struct MockChatBubble: View {
    let isUser: Bool
    let text: String

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            Text(text)
                .font(.subheadline)
                .foregroundColor(isUser ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isUser
                        ? AnyView(Theme.Colors.brandGradient)
                        : AnyView(Color(.systemGray5))
                )
                .cornerRadius(14)
                .cornerRadius(isUser ? 4 : 14,
                              corners: isUser ? .topRight : .bottomLeft)
            if !isUser { Spacer(minLength: 40) }
        }
    }
}

// MARK: - Final Page

struct OnboardingFinalPageView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon — same style as other slides
            Image(systemName: "book.closed.fill")
                .font(.system(size: 90))
                .foregroundStyle(Theme.Colors.brandGradientDiagonal)
                .shadow(color: Theme.Colors.brandShadow, radius: 20, x: 0, y: 10)
                .padding(.bottom, 36)

            VStack(spacing: 14) {
                Text("Ready to Start")
                    .font(.system(size: 32, weight: .bold))

                Text("Add your first book and never lose track of your reading again")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }

            Spacer()

            // CTA — always active, brand gradient, no age-gate here
            // Age verification moves to the sign-up flow per UX review
            Button {
                HapticManager.success()
                onComplete()
            } label: {
                Text("Get Started")
            }
            .buttonStyle(BrandGradientButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
