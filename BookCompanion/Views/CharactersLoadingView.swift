//
//  CharactersLoadingView.swift
//  BookCompanion
//
//  Created by Shree on 06/02/2026.
//  Updated: "Load More" button uses Theme.Colors.brandGradient + brandShadow,
//           "Cached" badge uses Theme.Colors.primary to match SummaryView exactly.
//

import SwiftUI

struct CharactersLoadingView: View {

    @StateObject private var viewModel: CharactersViewModel
    let chapter: Int
    let length: SummaryLength

    init(viewModel: CharactersViewModel, chapter: Int, length: SummaryLength) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.chapter = chapter
        self.length = length
    }

    var body: some View {
        Group {
            if viewModel.characters.isEmpty && viewModel.isLoading {
                // Initial loading — shimmer skeletons
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { _ in
                            CharacterShimmerCard()
                                .padding(.horizontal)
                        }
                    }

                    Spacer().frame(height: 40)

                    ProgressView()
                        .scaleEffect(1.2)

                    Text(LoadingMessages.randomCharacterMessage())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let error = viewModel.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)

                    Text("Failed to load characters")
                        .font(.headline)

                    Text(error.localizedDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if let aiError = error as? AIError,
                       let suggestion = aiError.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button("Try Again") {
                        Task { await viewModel.loadCharacters(chapter: chapter, length: length) }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.Colors.primary)
                }
                .padding()

            } else {
                CharactersView(characters: viewModel.characters)
                    .toolbar {
                        if viewModel.isCached {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                // Updated: Theme.Colors.primary matches the
                                // "Cached" badge in SummaryView exactly.
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Cached")
                                }
                                .font(.caption)
                                .foregroundColor(Theme.Colors.primary)
                            }
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        if viewModel.hasMore && !viewModel.isLoading {
                            Button {
                                Task {
                                    await viewModel.loadMoreCharacters(chapter: chapter, length: length)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                    Text("Load More Characters")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                // Updated: Theme gradient + brand shadow
                                .background(Theme.Colors.brandGradient)
                                .cornerRadius(Theme.CornerRadius.lg)
                                .shadow(color: Theme.Colors.brandShadow, radius: 8, y: 4)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                            .background(Color(.systemBackground))
                        }

                        if viewModel.isLoading && !viewModel.characters.isEmpty {
                            HStack {
                                ProgressView()
                                Text("Loading more…")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                        }
                    }
            }
        }
        .navigationTitle("Characters (Ch. \(chapter))")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadCharacters(chapter: chapter, length: length)
        }
    }
}

// MARK: - Shimmer Loading Card

struct CharacterShimmerCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(shimmerGradient)
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.xs)
                        .fill(shimmerGradient)
                        .frame(width: 120, height: 18)

                    RoundedRectangle(cornerRadius: Theme.CornerRadius.xs)
                        .fill(shimmerGradient)
                        .frame(width: 80, height: 14)
                }

                Spacer()
            }

            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xs)
                    .fill(shimmerGradient)
                    .frame(height: 14)

                RoundedRectangle(cornerRadius: Theme.CornerRadius.xs)
                    .fill(shimmerGradient)
                    .frame(height: 14)

                RoundedRectangle(cornerRadius: Theme.CornerRadius.xs)
                    .fill(shimmerGradient)
                    .frame(width: 200, height: 14)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(Theme.CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [Color(.systemGray5), Color(.systemGray6), Color(.systemGray5)],
            startPoint: isAnimating ? .leading : .trailing,
            endPoint: isAnimating ? .trailing : .leading
        )
    }
}
