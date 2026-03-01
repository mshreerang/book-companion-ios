//
//  AuthManager.swift
//  BookCompanion
//
//  Created by Shree on 22/02/2026.
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
            
            // Validate token with backend
            Task {
                await validateToken(token)
            }
        }
    }
    
    // MARK: - Sign In with Apple
    
    func signInWithApple() {
        AnalyticsManager.shared.track(event: "sign_in_started")
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        AnalyticsManager.shared.track(event: "sign_out")
        AnalyticsManager.shared.reset()
        
        KeychainManager.shared.clearAll()

        // Clear all character chat sessions so a different user signing in
        // on the same device cannot see previous conversation history.
        ChatSessionStore.clearAll()

        self.isSignedIn = false
        self.userId = nil
        self.userEmail = nil
        self.userName = nil
        print("✅ User signed out")
    }
    
    // MARK: - Authenticate with Backend
    
    private func authenticateWithBackend(identityToken: Data, userId: String, email: String?, name: PersonNameComponents?) async {
        isLoading = true
        error = nil
        
        guard let tokenString = String(data: identityToken, encoding: .utf8) else {
            self.error = "Failed to decode identity token"
            self.isLoading = false
            
            AnalyticsManager.shared.track(
                event: "sign_in_failed",
                properties: ["error": "Failed to decode identity token"]
            )
            
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
            
            // ✅ Identify user with RevenueCat using their Supabase UUID.
            // This is the app_user_id the webhook will receive.
            Task { await StoreManager.shared.login(userId: userId) }
            
            AnalyticsManager.shared.identify(
                userId: userId,
                properties: [
                    "email": userData["email"] as? String ?? "unknown",
                    "name": userData["name"] as? String ?? "unknown"
                ]
            )
            
            AnalyticsManager.shared.track(event: "sign_in_completed")
            
            print("✅ Authentication successful")
            print("   User ID: \(userId)")
            print("   Token saved to Keychain")
            
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
            
            AnalyticsManager.shared.track(
                event: "sign_in_failed",
                properties: ["error": error.localizedDescription]
            )
            
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
                print("✅ Token is valid")
                
                if let userData = json?["user"] as? [String: Any] {
                    self.userEmail = userData["email"] as? String
                    self.userName = userData["name"] as? String
                    
                    if let userId = self.userId {
                        AnalyticsManager.shared.identify(
                            userId: userId,
                            properties: [
                                "email": userData["email"] as? String ?? "unknown"
                            ]
                        )
                        // ✅ Re-identify with RC on app relaunch so entitlement
                        // is always tied to the correct Supabase user UUID.
                        Task { await StoreManager.shared.login(userId: userId) }
                    }
                }
            } else {
                print("⚠️ Token validation failed - signing out")
                signOut()
            }
            
        } catch {
            print("⚠️ Token validation error: \(error)")
            // Don't sign out on network errors
        }
    }
    
    // MARK: - Helpers
    
    private func formatName(_ name: PersonNameComponents?) -> String {
        guard let name = name else { return "User" }
        
        var parts: [String] = []
        if let given = name.givenName {
            parts.append(given)
        }
        if let family = name.familyName {
            parts.append(family)
        }
        
        return parts.isEmpty ? "User" : parts.joined(separator: " ")
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userId = credential.user
            let email = credential.email
            let fullName = credential.fullName
            
            guard let identityToken = credential.identityToken else {
                self.error = "Failed to get identity token"
                
                AnalyticsManager.shared.track(
                    event: "sign_in_failed",
                    properties: ["error": "Failed to get identity token"]
                )
                
                return
            }
            
            Task {
                await authenticateWithBackend(
                    identityToken: identityToken,
                    userId: userId,
                    email: email,
                    name: fullName
                )
            }
        }
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        self.error = error.localizedDescription
        self.isLoading = false
        
        AnalyticsManager.shared.track(
            event: "sign_in_failed",
            properties: ["error": error.localizedDescription]
        )
        
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
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        }
    }
}
