import SwiftUI

struct SummaryView: View {
    @StateObject private var viewModel: SummaryViewModel
    
    let chapter: Int
    let bookTitle: String
    let author: String
    let book: Book
    let language: Language
    
    @State private var showingShareSheet = false
    @EnvironmentObject private var storeManager: StoreManager
    @ObservedObject private var ttsManager = TextToSpeechManager.shared

    // Random loading message for variety during generation
    private let loadingMessage = LoadingMessages.randomSummaryMessage()

    init(
        viewModel: SummaryViewModel,
        chapter: Int,
        bookTitle: String,
        author: String,
        book: Book,
        language: Language
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.chapter = chapter
        self.bookTitle = bookTitle
        self.author = author
        self.book = book
        self.language = language
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Quota nudge banner — shown when 1 free summary remains
            if viewModel.showQuotaNudge {
                QuotaNudgeBanner(isShowing: $viewModel.showQuotaNudge)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showQuotaNudge)
            }

            // ✅ STATUS BADGES
            if viewModel.error == nil && !viewModel.isLoading {
                HStack(spacing: 8) {
                    Text("Safe up to Chapter \(chapter)")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                    
                    if viewModel.isCached {
                        Text("Cached")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            // ✅ CONTENT AREA
            Group {
                if viewModel.isLoading {
                    loadingContent
                } else if let error = viewModel.error {
                    errorView(error)
                } else if let summary = viewModel.summary {
                    summaryContent(summary.content)
                }
            }
        }
        .navigationTitle("Story So Far")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                toolbarButtons
            }
        }
        // Re-generate if chapter changes
        .task(id: chapter) {
            await viewModel.generate(chapter: chapter)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let summary = viewModel.summary {
                ShareSheet(items: [formatSummaryForSharing(summary)])
            }
        }
        // Paywall — shown only on explicit 429, never on network errors
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView(triggerReason: viewModel.paywallTriggerReason)
                .environmentObject(storeManager)
        }
    }
    
    // MARK: - Subviews
    
    private func summaryContent(_ content: String) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // ✅ Parse Markdown but preserve spacing
                let sections = parseSummaryWithMarkdown(content)
                ForEach(sections.indices, id: \.self) { index in
                    let section = sections[index]
                    Text(section.text)
                        .font(section.isHeader ? .headline : .body)
                        .fontWeight(section.isHeader ? .bold : .regular)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                }
            }
            .padding()
        }
    }
    
    // ✅ Helper: Parse summary and handle headers manually
    private func parseSummaryWithMarkdown(_ content: String) -> [(text: String, isHeader: Bool)] {
        var result: [(text: String, isHeader: Bool)] = []
        let lines = content.components(separatedBy: "\n")
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            // Check if it's a header (starts with ###)
            if trimmed.hasPrefix("###") {
                let headerText = trimmed.replacingOccurrences(of: "###", with: "").trimmingCharacters(in: .whitespaces)
                result.append((text: headerText, isHeader: true))
            } else {
                result.append((text: trimmed, isHeader: false))
            }
        }
        
        return result
    }

    private var loadingContent: some View {
        VStack(spacing: 20) {
            if !viewModel.streamingText.isEmpty {
                // ✅ Show streaming text as it arrives
                summaryContent(viewModel.streamingText)
            } else {
                // ✅ Show skeleton while waiting for first chunk
                SummarySkeleton()
            }
        }
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text("Connection Issue")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await viewModel.generate(chapter: chapter) }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }

    private var toolbarButtons: some View {
        HStack {
            // TTS Button
            if let summary = viewModel.summary {
                Button {
                    if ttsManager.isSpeaking {
                        ttsManager.stop()
                    } else {
                        ttsManager.speak(text: summary.content, language: language)  // ✅ FIXED
                    }
                } label: {
                    Image(systemName: ttsManager.isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
                }
            }
            
            // Share Button
            Button {
                showingShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .disabled(viewModel.summary == nil)
        }
    }
    
    // MARK: - Helpers
    
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

// MARK: - Quota Nudge Banner

struct QuotaNudgeBanner: View {
    @Binding var isShowing: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
            Text("1 free summary remaining this month — Go Pro for unlimited")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            Spacer()
            Button {
                withAnimation { isShowing = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .onAppear {
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation { isShowing = false }
            }
        }
    }
}

// MARK: - Share Sheet Helper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
