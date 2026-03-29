//
//  NotificationBanner.swift
//  BookCompanion
//
//  Created by Shree on 29/03/2026.
//

import SwiftUI

// MARK: - Banner Style

enum BannerStyle {
    case success
    case warning

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return Theme.Colors.secondary  // teal
        case .warning: return Theme.Colors.primary    // indigo
        }
    }
}

// MARK: - NotificationBanner

struct NotificationBanner: View {

    let message: String
    let style: BannerStyle
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: style.icon)
                .font(.title3)
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(style.color)
        .cornerRadius(Theme.CornerRadius.md)
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}
