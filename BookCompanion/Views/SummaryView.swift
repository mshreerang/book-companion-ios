import SwiftUI

struct SummaryView: View {

    @StateObject private var viewModel: SummaryViewModel
    @StateObject private var ttsManager = TextToSpeechManager.shared
    let chapter: Int
    let bookTitle: String
    let author: String
    
    // ✅ NEW: Pass these from parent view for character loading
    let makeCharactersViewModel: (Book, Language) -> CharactersViewModel
    
    // ✅ NEW: Share sheet state
    @State private var showingShareSheet = false
    
    // ✅ NEW: Random loading message (set once per view)
    private let loadingMessage = LoadingMessages.randomSummaryMessage()

    init(
        viewModel: SummaryViewModel,
        chapter: Int,
        bookTitle: String,
        author: String,
        makeCharactersViewModel: @escaping (Book, Language) -> CharactersViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.chapter = chapter
        self.bookTitle = bookTitle
        self.author = author
        self.makeCharactersViewModel = makeCharactersViewModel
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
            
            // ✅ STREAMING OR LOADING STATE
            if viewModel.isLoading {
                if viewModel.isStreaming && !viewModel.streamingText.isEmpty {
                    // ✅ SHOW STREAMING TEXT
                    ScrollView {
                        Text(viewModel.streamingText)
                            .font(.body)
                            .padding()
                            .textSelection(.enabled)
                    }
                } else {
                    // ✅ SHOW LOADING MESSAGE + SKELETON WHILE WAITING FOR FIRST CHUNK
                    VStack(spacing: 24) {
                        // ✅ FUN LOADING MESSAGE
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text(loadingMessage)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // SKELETON PREVIEW
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
                    }
                }
            } else if let error = viewModel.error {
                // ✅ ERROR STATE
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
                // ✅ SUCCESS STATE - SHOW COMPLETE SUMMARY
                ScrollView {
                    Text(summary.content)
                        .font(.body)
                        .padding()
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Story So Far")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // ✅ NEW: Share button
                    Button {
                        HapticManager.lightImpact()
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                    }
                    .disabled(viewModel.summary == nil)
                    .accessibilityLabel("Share Summary")
                    
                    // TTS Controls (Play/Pause or Stop)
                    if ttsManager.isSpeaking {
                        // Show Pause + Stop when playing/paused
                        Button {
                            HapticManager.lightImpact()
                            if ttsManager.isPaused {
                                ttsManager.resume()
                            } else {
                                ttsManager.pause()
                            }
                        } label: {
                            Image(systemName: ttsManager.isPaused ? "play.fill" : "pause.fill")
                                .font(.title3)
                        }
                        .accessibilityLabel(ttsManager.isPaused ? "Resume" : "Pause")
                        
                        Button {
                            HapticManager.lightImpact()
                            ttsManager.stop()
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.title3)
                        }
                        .accessibilityLabel("Stop")
                        
                    } else {
                        // Show Play when not playing
                        Button {
                            HapticManager.lightImpact()
                            if let summary = viewModel.summary {
                                ttsManager.speak(text: summary.content, language: summary.language)
                            }
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title3)
                        }
                        .disabled(viewModel.summary == nil)
                        .accessibilityLabel("Listen")
                    }
                    
                    // ✅ FIXED: Characters button navigates to CharactersLoadingView
                    if let summary = viewModel.summary {
                        NavigationLink {
                            CharactersLoadingView(
                                viewModel: makeCharactersViewModel(
                                    Book(
                                        id: summary.bookId,
                                        title: bookTitle,
                                        author: author,
                                        language: summary.language,
                                        totalChapters: chapter,  // Using chapter as temp value
                                        coverImageURL: nil,
                                        createdAt: Date()
                                    ),
                                    summary.language
                                ),
                                chapter: chapter,
                                length: summary.length
                            )
                        } label: {
                            Image(systemName: "person.2.fill")
                                .font(.title3)
                        }
                        .accessibilityLabel("Characters")
                    } else {
                        // Disabled state when no summary
                        Image(systemName: "person.2.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            // ✅ NEW: Share sheet
            if let summary = viewModel.summary {
                ShareSheet(items: [formatSummaryForSharing(summary)])
            }
        }
        .task(id: chapter) {
            await viewModel.generate(chapter: chapter)
        }
    }
    
    // ✅ NEW: Format summary for sharing (with book info)
    private func formatSummaryForSharing(_ summary: BookSummary) -> String {
        let header = author.isEmpty
            ? "📖 \(bookTitle)\nChapter \(chapter)"
            : "📖 \(bookTitle) by \(author)\nChapter \(chapter)"
        
        return """
        \(header)
        
        \(summary.content)
        
        ---
        Generated by BookCompanion
        """
    }
}

// ✅ NEW: iOS Share Sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
