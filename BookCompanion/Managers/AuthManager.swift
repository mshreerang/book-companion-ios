//
//  AuthManager.swift
//  BookCompanion
//
//  Updated by Shree on 06/03/2026.
//  Added: email/password sign in, create account, forgot password, account linking
//

import Foundation
import AuthenticationServices
import Combine

@MainActor
class AuthManager: NSObject, ObservableObject {
    
    @Published var isSignedIn = false
    @Published var userId: String?
    @Published var userEmail: String?
    @Published var isLoading = false
    @Published var error: String?
    @Published var userName: String?
    
    // Email auth specific states
    @Published var emailVerificationSent = false
    @Published var passwordResetSent = false
    
    static let shared = AuthManager()
    
    private override init() {
        super.init()
        checkSignInStatus()
    }
    
    // MARK: - Check Sign In Status
    
    func checkSignInStatus() {
        if let token = KeychainManager.shared.getUserToken(),
           let userId = KeychainManager.shared.getUserId() {
            self.userId = userId
            self.isSignedIn = true
            Task { await validateToken(token) }
        }
    }
    
    // MARK: - Sign In with Apple
    
    func signInWithApple() {
        AnalyticsManager.shared.track(event: "sign_in_started", properties: ["method": "apple"])
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - Sign In with Email
    
    func signInWithEmail(email: String, password: String) async {
        isLoading = true
        error = nil
        
        AnalyticsManager.shared.track(event: "sign_in_started", properties: ["method": "email"])
        
        do {
            let url = URL(string: "\(Config.apiEndpoint)/api/auth/email")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = ["action": "signin", "email": email, "password": password]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                throw AuthError.serverError("Invalid email or password.")
            }
            
            if httpResponse.statusCode == 403 {
                throw AuthError.serverError("Please verify your email before signing in. Check your inbox.")
            }
            
            if httpResponse.statusCode != 200 {
                let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let msg = errorBody?["error"] as? String ?? "Sign in failed. Please try again."
                throw AuthError.serverError(msg)
            }
            
            try await handleAuthResponse(data: data)
            
        } catch let authErr as AuthError {
            self.error = authErr.errorDescription
            self.isLoading = false
            AnalyticsManager.shared.track(event: "sign_in_failed", properties: ["method": "email", "error": authErr.localizedDescription])
        } catch {
            self.error = "Something went wrong. Please check your connection and try again."
            self.isLoading = false
            AnalyticsManager.shared.track(event: "sign_in_failed", properties: ["method": "email", "error": error.localizedDescription])
        }
    }
    
    // MARK: - Create Account with Email
    
    func createAccount(name: String, email: String, password: String) async {
        isLoading = true
        error = nil
        emailVerificationSent = false
        
        AnalyticsManager.shared.track(event: "sign_up_started", properties: ["method": "email"])
        
        do {
            let url = URL(string: "\(Config.apiEndpoint)/api/auth/email")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = ["action": "signup", "name": name, "email": email, "password": password]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 409 {
                let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let existingMethod = errorBody?["existingMethod"] as? String ?? "apple"
                if existingMethod == "apple" {
                    throw AuthError.serverError("An account with this email already exists. Sign in with Apple instead.")
                } else {
                    throw AuthError.serverError("An account with this email already exists. Try signing in.")
                }
            }
            
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
                let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let msg = errorBody?["error"] as? String ?? "Could not create account. Please try again."
                throw AuthError.serverError(msg)
            }
            
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let requiresVerification = json?["requiresVerification"] as? Bool ?? true
            
            if requiresVerification {
                self.emailVerificationSent = true
                self.isLoading = false
                AnalyticsManager.shared.track(event: "sign_up_verification_sent")
            } else {
                try await handleAuthResponse(data: data)
            }
            
        } catch let authErr as AuthError {
            self.error = authErr.errorDescription
            self.isLoading = false
            AnalyticsManager.shared.track(event: "sign_up_failed", properties: ["error": authErr.localizedDescription])
        } catch {
            self.error = "Something went wrong. Please check your connection and try again."
            self.isLoading = false
        }
    }
    
    // MARK: - Forgot Password
    
    func sendPasswordReset(email: String) async {
        isLoading = true
        error = nil
        passwordResetSent = false
        
        let url = URL(string: "\(Config.apiEndpoint)/api/auth/email")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["action": "reset-password", "email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // Fire and forget — always show success to prevent email enumeration
        _ = try? await URLSession.shared.data(for: request)
        
        self.passwordResetSent = true
        self.isLoading = false
        
        AnalyticsManager.shared.track(event: "password_reset_requested")
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        AnalyticsManager.shared.track(event: "sign_out")
        AnalyticsManager.shared.reset()
        
        KeychainManager.shared.clearAll()
        ChatSessionStore.clearAll()
        
        self.isSignedIn = false
        self.userId = nil
        self.userEmail = nil
        self.userName = nil
        self.emailVerificationSent = false
        self.passwordResetSent = false
        print("✅ User signed out")
    }
    
    // MARK: - Handle Auth Response (shared by Apple + Email)
    //
    // The backend always returns the Supabase UUID as `user.id` for both
    // Apple and email sign-ins. This means RevenueCat always receives a
    // consistent identifier regardless of which auth method the user chose.
    
    private func handleAuthResponse(data: Data) async throws {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let success = json?["success"] as? Bool,
              success,
              let userToken = json?["token"] as? String,
              let userData = json?["user"] as? [String: Any],
              let userId = userData["id"] as? String else {
            throw AuthError.invalidResponse
        }
        
        KeychainManager.shared.saveUserToken(userToken)
        KeychainManager.shared.saveUserId(userId)
        
        self.userId = userId
        self.userEmail = userData["email"] as? String
        self.userName = userData["name"] as? String
        self.isSignedIn = true
        self.isLoading = false
        
        // userId is now always the Supabase UUID — consistent for both
        // Apple and email users, so RevenueCat correctly merges entitlements.
        Task { await StoreManager.shared.login(userId: userId) }
        
        AnalyticsManager.shared.identify(
            userId: userId,
            properties: [
                "email": userData["email"] as? String ?? "unknown",
                "name": userData["name"] as? String ?? "unknown"
            ]
        )
        
        // Fire account_linked event if the backend silently merged an
        // email-only account with an Apple ID. Useful for tracking in PostHog.
        let accountLinked = json?["accountLinked"] as? Bool ?? false
        if accountLinked {
            AnalyticsManager.shared.track(
                event: "account_linked",
                properties: ["method": "apple_to_email"]
            )
            print("🔗 Account linked — email account merged with Apple ID")
        }
        
        AnalyticsManager.shared.track(event: "sign_in_completed")
        print("✅ Authentication successful — userId: \(userId)")
    }
    
    // MARK: - Authenticate with Backend (Apple)
    
    private func authenticateWithBackend(identityToken: Data, userId: String, email: String?, name: PersonNameComponents?) async {
        isLoading = true
        error = nil
        
        guard let tokenString = String(data: identityToken, encoding: .utf8) else {
            self.error = "Failed to decode identity token"
            self.isLoading = false
            return
        }
        
        do {
            let url = URL(string: "\(Config.apiEndpoint)/api/auth/apple")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "identityToken": tokenString,
                "user": [
                    "id": userId,
                    "email": email ?? "",
                    "name": formatName(name)
                ]
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorMessage = errorBody?["error"] as? String ?? "Authentication failed"
                throw AuthError.serverError(errorMessage)
            }
            
            try await handleAuthResponse(data: data)
            
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
            AnalyticsManager.shared.track(event: "sign_in_failed", properties: ["error": error.localizedDescription])
            print("❌ Authentication failed: \(error)")
        }
    }
    
    // MARK: - Validate Token
    
    private func validateToken(_ token: String) async {
        do {
            let url = URL(string: "\(Config.apiEndpoint)/api/auth/validate")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                print("⚠️ Token invalid - signing out")
                signOut()
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if json?["success"] as? Bool == true {
                if let userData = json?["user"] as? [String: Any] {
                    self.userEmail = userData["email"] as? String
                    self.userName = userData["name"] as? String
                    
                    if let userId = self.userId {
                        AnalyticsManager.shared.identify(userId: userId, properties: [
                            "email": userData["email"] as? String ?? "unknown"
                        ])
                        Task { await StoreManager.shared.login(userId: userId) }
                    }
                }
            } else {
                print("⚠️ Token validation failed - signing out")
                signOut()
            }
            
        } catch {
            print("⚠️ Token validation error (network): \(error)")
            // Don't sign out on network errors
        }
    }
    
    // MARK: - Helpers
    
    private func formatName(_ name: PersonNameComponents?) -> String {
        guard let name = name else { return "User" }
        var parts: [String] = []
        if let given = name.givenName { parts.append(given) }
        if let family = name.familyName { parts.append(family) }
        return parts.isEmpty ? "User" : parts.joined(separator: " ")
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let identityToken = credential.identityToken else {
                self.error = "Failed to get identity token"
                return
            }
            Task {
                await authenticateWithBackend(
                    identityToken: identityToken,
                    userId: credential.user,
                    email: credential.email,
                    name: credential.fullName
                )
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.error = error.localizedDescription
        self.isLoading = false
        AnalyticsManager.shared.track(event: "sign_in_failed", properties: ["method": "apple", "error": error.localizedDescription])
        print("❌ Sign in with Apple failed: \(error)")
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server"
        case .serverError(let message): return message
        }
    }
}
