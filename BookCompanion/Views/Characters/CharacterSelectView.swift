//
//  CharacterSelectView.swift
//  BookCompanion
//
//  Created by Shree on 28/04/2026.
//
//  Chat tab — direct character chat, no analysis step required.
//  Accepts shared CharacterCardsViewModel from ProgressInputView
//  so character names are fetched only once across both tabs.

import SwiftUI

struct CharacterSelectView: View {
    let book: Book
    let chapter: Int
    let language: Language
    let allBooks: [Book]

    // Shared with Characters tab — no duplicate API calls
    @ObservedObject var characterVM: CharacterCardsViewModel
    @EnvironmentObject private var store: StoreManager

    init(book: Book, chapter: Int, language: Language, allBooks: [Book] = [], characterVM: CharacterCardsViewModel) {
        self.book = book
        self.chapter = chapter
        self.language = language
        self.allBooks = allBooks
        self.characterVM = characterVM
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Safe up to Chapter \(chapter)")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.Colors.secondary.opacity(0.12))
                .foregroundColor(Theme.Colors.secondary)
                .cornerRadius(Theme.CornerRadius.sm)

            if characterVM.isLoadingNames {
                loadingView
            } else if let limited = characterVM.limitedMessage {
                limitedView(limited)
            } else if let error = characterVM.error {
                errorView(error)
            } else if characterVM.names.isEmpty {
                emptyView
            } else {
                characterList
            }
        }
    }

    // MARK: - Character List

    private var characterList: some View {
        VStack(spacing: 8) {
            ForEach(characterVM.names, id: \.self) { name in
                CharacterChatRow(
                    name: name,
                    book: book,
                    chapter: chapter,
                    language: language
                )
            }
        }
    }

    // MARK: - States

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView().scaleEffect(0.8)
            Text("Finding characters…")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Couldn't load characters")
                .font(.subheadline.bold())
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Try Again") {
                Task { await characterVM.loadNames() }
            }
            .font(.caption.bold())
            .foregroundColor(Theme.Colors.primary)
        }
        .padding(.vertical, 4)
    }

    private func limitedView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Characters unavailable")
                .font(.subheadline.bold())
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var emptyView: some View {
        Text("No characters found yet. Try reading more chapters.")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.vertical, 4)
    }
}

// MARK: - Character Chat Row

private struct CharacterChatRow: View {
    let name: String
    let book: Book
    let chapter: Int
    let language: Language

    @State private var showChat = false

    private static let avatarColors: [Color] = [
        Theme.Colors.primary,
        Theme.Colors.secondary,
        Color(red: 0.29, green: 0.38, blue: 0.31),
        Color(red: 0.48, green: 0.36, blue: 0.23),
        Color(red: 0.23, green: 0.37, blue: 0.31),
        Color(red: 0.42, green: 0.31, blue: 0.23),
    ]

    private var avatarColor: Color {
        let index = abs(name.hashValue) % Self.avatarColors.count
        return Self.avatarColors[index]
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        }
        return String(name.prefix(2))
    }

    var body: some View {
        Button {
            showChat = true
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(initials.uppercased())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )

                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(Theme.CornerRadius.lg)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showChat) {
            if FeatureFlags.characterChat {
                // Minimal CharacterCard — chat only needs fullName
                // No character analysis credit consumed here
                let minimalCard = CharacterCard(
                    id: name,
                    fullName: name,
                    description: nil,
                    relationships: nil,
                    currentSituation: nil,
                    role: nil
                )
                CharacterChatView(
                    character: minimalCard,
                    book: book,
                    chapter: chapter,
                    language: language
                )
            }
        }
    }
}
