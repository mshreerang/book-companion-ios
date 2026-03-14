//
//  CreateAccountView.swift
//  BookCompanion
//
//  Created by Shree on 06/03/2026.
//  Full create account journey: name, email, password, age check, terms.
//

import SwiftUI

struct CreateAccountView: View {
    
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isAgeVerified = false
    @State private var acceptedTerms = false
    
    // Field focus tracking for UX
    @FocusState private var focusedField: Field?
    
    enum Field { case name, email, password, confirmPassword }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 52))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 8)
                        
                        Text("Create Account")
                            .font(.title2.bold())
                        
                        Text("Join BookCompanion and start reading smarter")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 8)
                    
                    // MARK: - Verification Sent State
                    if authManager.emailVerificationSent {
                        verificationSentView
                    } else {
                        formFields
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onDisappear {
                // Reset verification state when sheet dismissed so re-opening works
                authManager.emailVerificationSent = false
                authManager.error = nil
            }
        }
    }
    
    // MARK: - Form Fields
    
    private var formFields: some View {
        VStack(spacing: 20) {
            
            // Fields
            VStack(spacing: 12) {
                
                // Name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Full Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    TextField("Your name", text: $name)
                        .focused($focusedField, equals: .name)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .name ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1.5)
                        )
                        .onSubmit { focusedField = .email }
                }
                
                // Email
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email Address")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    TextField("you@example.com", text: $email)
                        .focused($focusedField, equals: .email)
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
                                .stroke(focusedField == .email ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1.5)
                        )
                        .onSubmit { focusedField = .password }
                }
                
                // Password
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    SecureField("Min. 8 characters", text: $password)
                        .focused($focusedField, equals: .password)
                        .textContentType(.newPassword)
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .password ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1.5)
                        )
                        .onSubmit { focusedField = .confirmPassword }
                    
                    // Password strength indicator
                    if !password.isEmpty {
                        PasswordStrengthView(password: password)
                            .padding(.leading, 4)
                    }
                }
                
                // Confirm Password
                VStack(alignment: .leading, spacing: 6) {
                    Text("Confirm Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    SecureField("Re-enter password", text: $confirmPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .textContentType(.newPassword)
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    passwordMismatch ? Color.red.opacity(0.5) :
                                    (focusedField == .confirmPassword ? Color.blue.opacity(0.5) : Color.clear),
                                    lineWidth: 1.5
                                )
                        )
                    
                    if passwordMismatch {
                        Text("Passwords don't match")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.leading, 4)
                    }
                }
            }
            
            // MARK: - Age & Terms
            VStack(spacing: 14) {
                Divider()
                
                // Age verification — reuses AgeVerificationService
                Toggle(isOn: $isAgeVerified) {
                    Text("I am 13 years or older")
                        .font(.subheadline)
                }
                .toggleStyle(CheckboxToggleStyle())
                .onChange(of: isAgeVerified) { _, confirmed in
                    if confirmed { AgeVerificationService.shared.confirmAge() }
                    else { AgeVerificationService.shared.reset() }
                }
                
                // Terms & Privacy
                Toggle(isOn: $acceptedTerms) {
                    HStack(spacing: 4) {
                        Text("I agree to the")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Link("Terms of Use", destination: URL(string: "https://mshreerang.github.io/book-companion-ios/terms.html")!)
                            .font(.subheadline)
                        Text("and")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Link("Privacy Policy", destination: URL(string: "https://mshreerang.github.io/book-companion-ios/privacy-policy.html")!)
                            .font(.subheadline)
                    }
                }
                .toggleStyle(CheckboxToggleStyle())
                
                Divider()
            }
            
            // MARK: - Error
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
            }
            
            // MARK: - Submit Button
            Button {
                focusedField = nil
                Task {
                    await authManager.createAccount(
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password
                    )
                }
            } label: {
                Group {
                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Account")
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
                .shadow(color: canSubmit ? .blue.opacity(0.25) : .clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!canSubmit || authManager.isLoading)
            
            // Already have account
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)
                    Text("Sign in")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                .font(.subheadline)
            }
        }
    }
    
    // MARK: - Verification Sent
    
    private var verificationSentView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "envelope.badge.checkmark.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                VStack(spacing: 8) {
                    Text("Check Your Email")
                        .font(.title3.bold())
                    
                    Text("We've sent a verification link to\n**\(email)**\n\nClick the link in the email to activate your account, then come back and sign in.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            Text("Didn't receive it? Check your spam folder, or try again with a different email.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
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
        .padding(.top, 8)
    }
    
    // MARK: - Validation
    
    private var passwordMismatch: Bool {
        !confirmPassword.isEmpty && password != confirmPassword
    }
    
    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") && email.contains(".") &&
        password.count >= 8 &&
        password == confirmPassword &&
        isAgeVerified &&
        acceptedTerms
    }
}

// MARK: - Password Strength Indicator

private struct PasswordStrengthView: View {
    let password: String
    
    private var strength: PasswordStrength {
        if password.count < 8 { return .weak }
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        let score = [hasUppercase, hasNumber, hasSpecial].filter { $0 }.count
        if score >= 2 { return .strong }
        if score == 1 { return .medium }
        return .weak
    }
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < strength.filledBars ? strength.color : Color(.systemGray4))
                    .frame(height: 3)
            }
            Text(strength.label)
                .font(.caption2)
                .foregroundColor(strength.color)
        }
        .animation(.easeInOut(duration: 0.2), value: strength.filledBars)
    }
    
    private enum PasswordStrength: Int {
        case weak = 1, medium = 2, strong = 3
        
        var filledBars: Int { rawValue }
        var color: Color {
            switch self {
            case .weak: return .red
            case .medium: return .orange
            case .strong: return .green
            }
        }
        var label: String {
            switch self {
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            }
        }
    }
}

#Preview {
    CreateAccountView(authManager: AuthManager.shared)
}
