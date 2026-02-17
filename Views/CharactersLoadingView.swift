//
//  CharactersLoadingView.swift
//  BookCompanion
//
//  Created by Shree on 06/02/2026.
//

import SwiftUI

struct CharactersLoadingView: View {
    
    @StateObject private var viewModel: CharactersViewModel
    let chapter: Int
    let length: SummaryLength
    
    init(
        viewModel: CharactersViewModel,
        chapter: Int,
        length: SummaryLength
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.chapter = chapter
        self.length = length
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Loading Characters")
                        .font(.headline)
                    
                    Text("This may take a few seconds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
                        Task {
                            await viewModel.loadCharacters(chapter: chapter, length: length)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                CharactersView(characters: viewModel.characters)
                    .toolbar {
                        if viewModel.isCached {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Cached")
                                }
                                .font(.caption)
                                .foregroundColor(.green)
                            }
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
