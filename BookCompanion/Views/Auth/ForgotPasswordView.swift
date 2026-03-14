//
//  ForgotPasswordView.swift
//  BookCompanion
//
//  Created by Shree on 06/03/2026.
//

import SwiftUI

struct ForgotPasswordView: View {
    
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @FocusState private var emailFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer().frame(height: 8)
                
                // MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    Text("Reset Password")
                        .font(.title2.bold())
                    
                    Text("Enter your email and we'll send you a link to reset your password.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                if authManager.passwordResetSent {
                    // MARK: - Success State
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.green)
                            
                            Text("Email Sent")
                                .font(.headline)
                            
                            Text("If an account exists for **\(email)**, you'll receive a reset link shortly.\n\nCheck your spam folder if you don't see it.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Back to Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                } else {
                    // MARK: - Input State
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                            
                            TextField("you@example.com", text: $email)
                                .focused($emailFocused)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .textContentType(.emailAddress)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(emailFocused ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                )
                                .onSubmit { sendReset() }
                        }
                        
                        if let error = authManager.error {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 4)
                        }
                        
                        Button {
                            sendReset()
                        } label: {
                            Group {
                                if authManager.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Send Reset Link")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: canSubmit ? [.blue, .purple] : [.gray, .gray],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                        }
                        .disabled(!canSubmit || authManager.isLoading)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { emailFocused = true }
            .onDisappear {
                authManager.passwordResetSent = false
                authManager.error = nil
            }
        }
    }
    
    private var canSubmit: Bool {
        email.contains("@") && email.contains(".")
    }
    
    private func sendReset() {
        guard canSubmit else { return }
        emailFocused = false
        Task { await authManager.sendPasswordReset(email: email) }
    }
}

#Preview {
    ForgotPasswordView(authManager: AuthManager.shared)
}
