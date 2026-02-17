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

            if viewModel.isLoading {
                VStack {
                    Spacer()
                    VStack(spacing: Theme.Spacing.md) {
                        ProgressView()
                        Text("Preparing your summary...")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Failed to generate summary")
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // ✅ Add recovery suggestion if available
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
                            await viewModel.generate(chapter: chapter)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                Spacer()
            } else if let summary = viewModel.summary {
                ScrollView {
                    Text(summary.content)
                        .font(.body)
                        .padding(.top, 8)
                }

                Spacer()
              }
        }
        .padding()
        .navigationTitle("Story So Far")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Listen button
                    Button {
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
