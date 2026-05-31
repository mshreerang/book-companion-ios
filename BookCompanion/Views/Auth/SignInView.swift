//
//  SignInView.swift
//  BookCompanion
//
//  Redesigned: icon-based auth buttons, prominent guest mode,
//  clean minimal layout.
//

import SwiftUI

struct SignInView: View {

    @ObservedObject var authManager: AuthManager

    @EnvironmentObject private var deepLinkManager: DeepLinkManager

    @State private var email = ""
    @State private var password = ""
    @State private var showEmailFields = false
    @State private var showCreateAccount = false
    @State private var showForgotPassword = false
    @State private var bannerMessage: String? = nil
    @State private var bannerStyle: BannerStyle = .success

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: geo.size.height * 0.12)

                    // MARK: - Header
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 68))
                            .foregroundStyle(Theme.Colors.brandGradientDiagonal)

                        VStack(spacing: 6) {
                            Text("BookCompanion")
                                .font(.system(size: 30, weight: .bold))

                            Text("Your reading companion")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 44)

                    // MARK: - Auth icons row
                    VStack(spacing: 14) {

                        if showEmailFields {
                            // ── Expanded email fields ─────────────────────
                            emailSignInFields
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .padding(.horizontal, 32)
                        } else {
                            // ── Icon buttons row ─────────────────────────
                            HStack(spacing: 24) {

                                // Apple
                                Button {
                                    if !authManager.isLoading {
                                        authManager.signInWithApple()
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color(UIColor.label))
                                            .frame(width: 60, height: 60)
                                        if authManager.isLoading {
                                            ProgressView()
                                                .tint(Color(UIColor.systemBackground))
                                        } else {
                                            Image(systemName: "applelogo")
                                                .font(.system(size: 26))
                                                .foregroundColor(Color(UIColor.systemBackground))
                                        }
                                    }
                                }
                                .disabled(authManager.isLoading)

                                // Email
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        showEmailFields = true
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color(.systemGray5))
                                            .frame(width: 60, height: 60)
                                        Image(systemName: "envelope.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }

                            Text("Sign in with Apple or Email")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                            .padding(.horizontal, 32)
                            .padding(.top, 4)
                        }

                        // Create account — only shown when email fields are expanded
                        if showEmailFields {
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
                            .padding(.top, 4)
                        }
                    }

                    // MARK: - Guest mode button
                    VStack(spacing: 8) {
                        HStack {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 0.5)
                            Text("or")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 0.5)
                        }
                        .padding(.horizontal, 40)

                        Button {
                            HapticManager.lightImpact()
                            GuestManager.shared.enterGuestMode()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 15))
                                Text("Try it first — no account needed")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundColor(Theme.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                                    .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.top, 24)

                    // MARK: - Footer
                    Text("Your data is protected however you sign in.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 28)

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
        .overlay(alignment: .top) {
            if let message = bannerMessage {
                NotificationBanner(
                    message: message,
                    style: bannerStyle,
                    onDismiss: { bannerMessage = nil }
                )
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: bannerMessage)
            }
        }
        .onChange(of: deepLinkManager.pendingLink) { _, link in
            guard let link else { return }
            switch link {
            case .emailConfirmed:
                bannerStyle = .success
                bannerMessage = "Email confirmed! You can now sign in."
                deepLinkManager.consume()
            case .resetPassword:
                bannerStyle = .success
                bannerMessage = "Password updated. Please sign in."
                deepLinkManager.consume()
            case .search:
                break
            }
        }
    }

    // MARK: - Email sign-in fields

    private var emailSignInFields: some View {
        VStack(spacing: 12) {

            // Back button to return to icon row
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showEmailFields = false
                    email = ""
                    password = ""
                    authManager.error = nil
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption.bold())
                    Text("Back")
                        .font(.subheadline)
                }
                .foregroundColor(Theme.Colors.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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
