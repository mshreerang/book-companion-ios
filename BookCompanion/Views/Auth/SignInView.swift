//
//  SignInView.swift
//  BookCompanion
//
//  Created by Shree on 22/02/2026.
//

import SwiftUI

struct SignInView: View {
    
    @ObservedObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Icon/Logo
            Image(systemName: "book.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 20)
            
            // Title
            VStack(spacing: 8) {
                Text("Welcome to BookCompanion")
                    .font(.title.bold())
                
                Text("Your AI-powered reading companion")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sign in button
            VStack(spacing: 16) {
                if authManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else {
                    SignInWithAppleButton(authManager: authManager)
                }
                
                // Error message
                if let error = authManager.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, 40)
            
            // Privacy note
            Text("We use Sign in with Apple to protect your privacy")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
        }
        .padding()
    }
}

#Preview {
    SignInView(authManager: AuthManager.shared)
}
