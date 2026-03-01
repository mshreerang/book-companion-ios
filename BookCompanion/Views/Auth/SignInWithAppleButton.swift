//
//  SignInWithAppleButton.swift
//  BookCompanion
//
//  Created by Shree on 22/02/2026.
//

import SwiftUI
import AuthenticationServices

struct SignInWithAppleButton: View {
    
    @ObservedObject var authManager: AuthManager
    
    var body: some View {
        Button {
            authManager.signInWithApple()
        } label: {
            HStack {
                Image(systemName: "applelogo")
                    .font(.title3)
                
                Text("Sign in with Apple")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.black)
            .cornerRadius(12)
        }
        .disabled(authManager.isLoading)
    }
}

#Preview {
    SignInWithAppleButton(authManager: AuthManager.shared)
        .padding()
}
