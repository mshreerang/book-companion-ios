//
//  SignInView.swift
//  BookCompanion
//
//  Updated by Shree on 06/03/2026.
//  Added: email/password sign in, create account, forgot password links
//

import SwiftUI

struct SignInView: View {
    
    @ObservedObject var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var showEmailFields = false
    @State private var showCreateAccount = false
    @State private var showForgotPassword = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                // MARK: - Header
                VStack(spacing: 16) {
                    Spacer().frame(height: 60)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(spacing: 8) {
                        Text("BookCompanion")
                            .font(.system(size: 32, weight: .bold))
                        
                        Text("Your AI-powered reading companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 56)
                
                // MARK: - Auth Buttons
                VStack(spacing: 12) {
                    
                    // Sign in with Apple — always shown, always primary
                    if authManager.isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                            .frame(height: 50)
                    } else {
                        SignInWithAppleButton(authManager: authManager)
                    }
                    
                    // Divider
                    HStack {
                        Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                        Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                    }
                    .padding(.vertical, 4)
                    
                    // Email/Password section
                    if showEmailFields {
                        emailSignInFields
                            .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        // Collapsed email button
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showEmailFields = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "envelope")
                                    .font(.title3)
                                Text("Continue with Email")
                                    .font(.headline)
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Error message
                    if let error = authManager.error {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                    }
                    
                    // Create Account
                    Button {
                        showCreateAccount = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(.secondary)
                            Text("Create one")
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                
                // MARK: - Footer
                Text("We use Sign in with Apple to protect your privacy")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 40)
                    .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showCreateAccount) {
            CreateAccountView(authManager: authManager)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(authManager: authManager)
        }
        .animation(.default, value: authManager.error)
    }
    
    // MARK: - Email Sign In Fields
    
    private var emailSignInFields: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                SecureField("Password", text: $password)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            
            Button {
                showForgotPassword = true
            } label: {
                Text("Forgot password?")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 4)
            
            Button {
                Task {
                    await authManager.signInWithEmail(email: email, password: password)
                }
            } label: {
                Group {
                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: canSubmit ? [.blue, .purple] : [.gray, .gray],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(!canSubmit || authManager.isLoading)
        }
    }
    
    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= 6
    }
}

#Preview {
    SignInView(authManager: AuthManager.shared)
}
