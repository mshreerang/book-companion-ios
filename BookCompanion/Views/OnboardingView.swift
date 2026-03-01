//
//  OnboardingView.swift
//  BookCompanion
//
//  Created by Shree on 07/02/2026.
//

import SwiftUI

struct OnboardingView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TabView(selection: $currentPage) {

                // Page 1: Welcome
                OnboardingPageView(
                    systemImage: "book.pages.fill",
                    title: "Welcome to BookCompanion",
                    description: "Your AI reading assistant for complex books\n\nआपका AI पढ़ने का सहायक\n\nतुमचा AI वाचन सहाय्यक",
                    gradientColors: [.blue, .cyan]
                )
                .tag(0)

                // Page 2: Smart Summaries
                OnboardingPageView(
                    systemImage: "sparkles.rectangle.stack.fill",
                    title: "Smart Summaries",
                    description: "Get spoiler-free recaps and character guides\n\nस्पॉयलर-मुक्त सारांश प्राप्त करें\n\nस्पॉयलर-मुक्त सारांश मिळवा",
                    gradientColors: [.purple, .pink]
                )
                .tag(1)

                // Page 3: Character Chat  ← NEW
                OnboardingCharacterChatPageView()
                    .tag(2)

                // Page 4: Ready to Start (age verification + CTA)
                OnboardingFinalPageView(onComplete: {
                    completeOnboarding()
                })
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
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

// MARK: - Character Chat Onboarding Page

struct OnboardingCharacterChatPageView: View {

    // Animates the mock chat bubbles appearing one by one
    @State private var visibleBubbles = 0

    // Sample exchange — short enough to fit comfortably on screen
    private let bubbles: [(isUser: Bool, text: String)] = [
        (false, "So… you've read this far. What is it you want to know?"),
        (true,  "Do you think Harry put his name in the Goblet?"),
        (false, "Absolutely not. I know Harry. He would never seek that kind of attention."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.indigo, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .indigo.opacity(0.3), radius: 20, x: 0, y: 10)
                .padding(.bottom, 28)

            VStack(spacing: 10) {
                Text("Talk to the Characters")
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Ask them anything — they only know\nwhat you've read so far.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // ── Mock chat preview ──────────────────────────────────────
            VStack(alignment: .leading, spacing: 10) {
                // Character label
                HStack(spacing: 8) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.indigo, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
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

// Small mock bubble — no dependency on CharacterChatBubble
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
                    ? AnyView(LinearGradient(
                        colors: [.blue.opacity(0.85), .purple.opacity(0.85)],
                        startPoint: .leading, endPoint: .trailing
                      ))
                    : AnyView(Color(.systemGray5))
                )
                .cornerRadius(14)
                .cornerRadius(isUser ? 4 : 14,
                              corners: isUser ? .topRight : .bottomLeft)
            if !isUser { Spacer(minLength: 40) }
        }
    }
}

// MARK: - Onboarding Page (unchanged)

struct OnboardingPageView: View {
    let systemImage: String
    let title: String
    let description: String
    let gradientColors: [Color]

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: systemImage)
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: gradientColors[0].opacity(0.3), radius: 20, x: 0, y: 10)

            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Final Page with Age Verification (unchanged)

struct OnboardingFinalPageView: View {
    let onComplete: () -> Void

    @State private var isAgeVerified = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "book.closed.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .green.opacity(0.3), radius: 20, x: 0, y: 10)

            VStack(spacing: 16) {
                Text("Ready to Start")
                    .font(.system(size: 34, weight: .bold))

                Text("Add your first book and never lose track of your reading again")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 20) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 32)

                Toggle(isOn: $isAgeVerified) {
                    Text("I am 13 years or older")
                }
                .toggleStyle(CheckboxToggleStyle())
                .padding(.horizontal, 32)
                .onChange(of: isAgeVerified) { _, newValue in
                    if newValue {
                        AnalyticsManager.shared.track(event: "age_verified")
                    }
                }

                Button {
                    HapticManager.success()
                    onComplete()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: isAgeVerified ? [.blue, .purple] : [.gray, .gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: isAgeVerified ? .blue.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
                }
                .disabled(!isAgeVerified)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .padding()
    }
}



#Preview {
    OnboardingView(onComplete: {})
}
