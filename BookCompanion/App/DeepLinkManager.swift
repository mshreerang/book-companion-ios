//
//  DeepLinkManager.swift
//  BookCompanion
//
//  Created by Shree on 29/03/2026.
//

import Foundation
import Combine

// MARK: - DeepLink enum

enum DeepLink: Equatable {
    case emailConfirmed
    case resetPassword
    case search
}

// MARK: - DeepLinkManager

final class DeepLinkManager: ObservableObject {

    @Published var pendingLink: DeepLink? = nil

    /// Call this from .onOpenURL in BookCompanionApp.
    /// Parses the incoming URL and stores the result as pendingLink.
    func handle(url: URL) {
        guard url.scheme == "bookcompanion" else { return }

        switch url.host {
        case "confirmed":
            pendingLink = .emailConfirmed

        case "reset-password":
            pendingLink = .resetPassword

        case "search":
            pendingLink = .search

        case nil:
            // Supabase password reset redirects to bookcompanion:// with no host
            pendingLink = .resetPassword

        default:
            break
        }
    }

    /// Call this once the pending link has been handled by a view.
    func consume() {
        pendingLink = nil
    }
}
