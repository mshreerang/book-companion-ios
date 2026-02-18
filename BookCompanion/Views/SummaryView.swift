import SwiftUI

struct SummaryView: View {

    @StateObject private var viewModel: SummaryViewModel
    @StateObject private var ttsManager = TextToSpeechManager.shared
    let chapter: Int

    init(
        viewModel: SummaryViewModel,
        chapter: Int
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.chapter = chapter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Only show badges when NOT in error/loading state
            if viewModel.error == nil && !viewModel.isLoading {
                Text("Safe up to Chapter \(chapter)")
                    .font(.caption)
                    .padding(6)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(6)
                
                if viewModel.isCached {
                    Text("Previously generated")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
                
                HStack {
                    Spacer()
                    
                    Button {
                        Task {
                            await viewModel.regenerate(chapter: chapter)
                        }
                    } label: {
                        Text("Regenerate summary")
                            .font(.caption)
                    }
                    .disabled(viewModel.isLoading)
                    
                    Spacer()
                }
            }
            
            // Loading state - FIXED!
            if viewModel.isLoading {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Chapter indicator skeleton
                        SkeletonBox(width: 180, height: 12, cornerRadius: 6)
                        
                        Spacer().frame(height: 8)
                        
                        // Summary content skeleton
                        SummarySkeleton()
                    }
                    .padding()
                }
            } else if let error = viewModel.error {
                // Error state
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        // Error icon with animation
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 8) {
                            Text("Couldn't Generate Summary")
                                .font(.title3.weight(.semibold))
                            
                            Text(error.localizedDescription)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Recovery suggestion
                        if let aiError = error as? AIError,
                           let suggestion = aiError.recoverySuggestion {
                            VStack(spacing: 8) {
                                Divider()
                                    .padding(.vertical, 8)
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.blue)
                                    Text(suggestion)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Try again button
                        Button {
                            Task {
                                await viewModel.generate(chapter: chapter)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Try Again")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if let summary = viewModel.summary {
                // Success state - show summary
                ScrollView {
                    Text(summary.content)
                        .font(.body)
                        .padding()
                }
            }
        }
        .navigationTitle("Story So Far")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Listen button
                    Button {
                        HapticManager.lightImpact()
                        
                        if ttsManager.isSpeaking {
                            ttsManager.stop()
                        } else {
                            if let summary = viewModel.summary {
                                ttsManager.speak(text: summary.content, language: summary.language)
                            }
                        }
                    } label: {
                        Label(
                            ttsManager.isSpeaking ? "Stop" : "Listen",
                            systemImage: ttsManager.isSpeaking ? "stop.fill" : "speaker.wave.2.fill"
                        )
                    }
                    .disabled(viewModel.summary == nil)
                    
                    // Characters button
                    NavigationLink {
                        CharactersView(characters: viewModel.characters)
                    } label: {
                        Label("Characters", systemImage: "person.2.fill")
                    }
                }
            }
        }
        .task(id: chapter) {
            await viewModel.generate(chapter: chapter)
        }
    }
}
