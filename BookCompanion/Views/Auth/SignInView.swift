//
//  SignInView.swift
//  BookCompanion
//
//  Updated by Shree on 06/03/2026.
//  Updated: fixed misleading privacy footer copy, vertically centred
//           layout, updated brand colours to indigo/teal.
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
        // GeometryReader lets us vertically centre the content group
        // regardless of whether email fields are expanded or not.
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: geo.size.height * 0.1)

                    // MARK: - Header
                    VStack(spacing: 16) {
                        // Brand mark — consistent with Settings and Transparency screens
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 68))
                            .foregroundStyle(Theme.Colors.brandGradientDiagonal)

                        VStack(spacing: 6) {
                            Text("BookCompanion")
                                .font(.system(size: 30, weight: .bold))

                            Text("Your AI-powered reading companion")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 48)

                    // MARK: - Auth buttons
                    VStack(spacing: 12) {

                        if authManager.isLoading && !showEmailFields {
                            ProgressView()
                                .scaleEffect(1.2)
                                .frame(height: 50)
                        } else {
                            SignInWithAppleButton(authManager: authManager)
                        }

                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.25))
                                .frame(height: 0.5)
                            Text("or")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.25))
                                .frame(height: 0.5)
                        }

                        // Email section
                        if showEmailFields {
                            emailSignInFields
                                .transition(.move(edge: .top).combined(with: .opacity))
                        } else {
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
                                .cornerRadius(Theme.CornerRadius.lg)
                            }
                        }

                        // Error
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

                        // Create account
                        Button { showCreateAccount = true } label: {
                            HStack(spacing: 4) {
                                Text("New here?")
                                    .foregroundColor(.secondary)
                                Text("Create an account")
                                    .foregroundColor(Theme.Colors.primary)
                                    .fontWeight(.medium)
                            }
                            .font(.subheadline)
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 32)

                    // MARK: - Footer
                    // Updated: removed misleading Apple-only privacy claim.
                    // Both sign-in methods protect your privacy equally.
                    Text("Your data is protected however you sign in.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 32)

                    Spacer(minLength: geo.size.height * 0.1)
                }
                .frame(minHeight: geo.size.height)
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

    // MARK: - Email sign-in fields

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
                    .cornerRadius(Theme.CornerRadius.lg)

                SecureField("Password", text: $password)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .cornerRadius(Theme.CornerRadius.lg)
            }

            Button { showForgotPassword = true } label: {
                Text("Forgot password?")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.primary)
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
                        ProgressView().tint(.white)
                    } else {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    canSubmit
                        ? Theme.Colors.brandGradient
                        : LinearGradient(colors: [.gray, .gray],
                                         startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(Theme.CornerRadius.lg)
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
