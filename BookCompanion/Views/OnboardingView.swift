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
                    title: "Welcome to\nBookCompanion",
                    description: "Never lose your place in a book again. Get instant summaries and character reminders.",
                    gradientColors: [.blue, .cyan]
                )
                .tag(0)
                
                // Page 2: How it Works
                OnboardingPageView(
                    systemImage: "sparkles.rectangle.stack.fill",
                    title: "Choose Your Mode",
                    description: "Use offline sample data for free, or enable AI for personalized summaries of any book.",
                    gradientColors: [.purple, .pink]
                )
                .tag(1)
                
                // Page 3: Get Started
                OnboardingFinalPageView(onComplete: {
                    completeOnboarding()
                })
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
            onComplete()
        }
    }
}

// MARK: - Onboarding Page

struct OnboardingPageView: View {
    let systemImage: String
    let title: String
    let description: String
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon with gradient
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

// MARK: - Final Page

struct OnboardingFinalPageView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
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
            
            // Get Started Button
            Button {
                onComplete()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .padding()
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
