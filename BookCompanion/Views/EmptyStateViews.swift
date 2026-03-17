//
//  EmptyStateViews.swift
//  BookCompanion
//
//  Created by Shree on 19/02/2026.
//  Updated: all hardcoded icon gradient colours replaced with Theme
//           brand colours so empty states are visually consistent
//           with the rest of the app.
//

import SwiftUI

// NOTE: EmptyLibraryView is defined in EmptyLibraryView.swift — not here.

// MARK: - Empty Search Results

struct EmptySearchResultsView: View {
    let searchQuery: String

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    // Was orange/red — now uses brand gradient
                    .foregroundStyle(Theme.Colors.brandGradientDiagonal)

                VStack(spacing: 12) {
                    Text("No Books Found")
                        .font(.title2.weight(.bold))

                    Text("We couldn't find any books matching \"\(searchQuery)\"")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 8) {
                    Text("Try:")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        TipRow(icon: "checkmark.circle.fill", text: "Checking your spelling")
                        TipRow(icon: "checkmark.circle.fill", text: "Using different keywords")
                        TipRow(icon: "checkmark.circle.fill", text: "Searching by author name")
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty Characters View

struct EmptyCharactersView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 60))
                    // Was green/blue — now brand gradient
                    // Icon updated to chat bubbles to match the
                    // "Chat with Characters" rename throughout the app
                    .foregroundStyle(Theme.Colors.brandGradientDiagonal)

                VStack(spacing: 12) {
                    Text("No Characters Yet")
                        .font(.title2.weight(.bold))

                    Text("Generate a summary first, and you'll be able to chat with your book's characters here")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - No Summary View

struct NoSummaryView: View {
    let onGenerate: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.gradientStart.opacity(0.08))
                        .frame(width: 120, height: 120)

                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60))
                        // Was purple/pink — now brand gradient
                        .foregroundStyle(Theme.Colors.brandGradientDiagonal)
                }

                VStack(spacing: 12) {
                    Text("No Summary Yet")
                        .font(.title2.weight(.bold))

                    Text("Generate an AI-powered summary to recap the story so far")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button {
                    HapticManager.lightImpact()
                    onGenerate()
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate Summary")
                    }
                }
                .buttonStyle(BrandGradientButtonStyle())
                .padding(.horizontal, 48)
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tip Row

private struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Theme.Colors.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Empty Search") {
    EmptySearchResultsView(searchQuery: "Nonexistent Book")
}

#Preview("Empty Characters") {
    EmptyCharactersView()
}

#Preview("No Summary") {
    NoSummaryView(onGenerate: {})
}
