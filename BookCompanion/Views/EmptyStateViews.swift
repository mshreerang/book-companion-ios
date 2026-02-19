//
//  EmptyStateViews.swift
//  BookCompanion
//
//  Created by Shree on 19/02/2026.
//

import SwiftUI

// NOTE: EmptyLibraryView already exists in your project, so we're NOT redefining it here

// MARK: - Empty Search Results View

struct EmptySearchResultsView: View {
    let searchQuery: String
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
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
                // Icon
                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 12) {
                    Text("No Characters Yet")
                        .font(.title2.weight(.bold))
                    
                    Text("Generate a summary first, and character profiles will appear here")
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

// MARK: - No Summary Generated View

struct NoSummaryView: View {
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
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
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Helper Views

private struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.green)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("Empty Search") {
    EmptySearchResultsView(searchQuery: "Nonexistent Book")
}

#Preview("Empty Characters") {
    EmptyCharactersView()
}

#Preview("No Summary") {
    NoSummaryView(onGenerate: {})
}
