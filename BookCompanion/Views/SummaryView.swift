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

            // Quota nudge
            if viewModel.showQuotaNudge {
                QuotaNudgeBanner(isShowing: $viewModel.showQuotaNudge)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showQuotaNudge)
            }

            // Status badges row
            if viewModel.error == nil && !viewModel.isLoading {
                HStack(spacing: 6) {

                    // Spoiler-safe badge
                    Text("Safe up to Chapter \(chapter)")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.secondary.opacity(0.12))
                        .foregroundColor(Theme.Colors.secondary)
                        .cornerRadius(Theme.CornerRadius.xs)

                    // Cached badge
                    if viewModel.isCached {
                        Text("Cached")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.Colors.primary.opacity(0.10))
                            .foregroundColor(Theme.Colors.primary)
                            .cornerRadius(Theme.CornerRadius.xs)
                    }

                    // Series context badge — shown when:
                    // 1. Book is in a series
                    // 2. Book is not the first entry (context only meaningful from book 2+)
                    //    OR has completed prior books to reference
                    // Tells the user the AI is aware of earlier books in the series.
                    if let seriesName = book.seriesName,
                       let position = book.seriesPosition,
                       position > 1 {
                        HStack(spacing: 3) {
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 8, weight: .semibold))
                            Text("Series context: \(seriesName)")
                                .font(.caption.bold())
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.primary.opacity(0.10))
                        .foregroundColor(Theme.Colors.primary)
                        .cornerRadius(Theme.CornerRadius.xs)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            Group {
                if viewModel.isLoading {
                    loadingContent
                } else if let error = viewModel.error {
                    errorView(error)
                } else if let summary = viewModel.summary {
                    summaryContent(summary.content)
                }
            }

            if isVaniActive {
                ActiveNarratorView(
                    viewModel:        viewModel.vaniPlayer,
                    fallbackText:     viewModel.summary?.content ?? "",
                    fallbackLanguage: language,
                    chapterTitle:     "Story So Far · Chapter \(chapter)",
                    onPrewarmTap: viewModel.summary.map { summary in {
                        Task {
                            await viewModel.vaniPlayer.prewarm(
                                text: summary.content,
                                language: language,
                                bookId: book.id.uuidString,
                                chapterNumber: chapter
                            )
                        }
                    }},
                    isSummaryReady: viewModel.summary != nil
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVaniActive)
            }
        }
        .navigationTitle("Story So Far")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                toolbarButtons
            }
        }
        .task(id: chapter) {
            await viewModel.generate(chapter: chapter)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let summary = viewModel.summary {
                ShareSheet(items: [formatSummaryForSharing(summary)])
            }
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView(triggerReason: viewModel.paywallTriggerReason)
                .environmentObject(storeManager)
        }
    }

    // MARK: - Vani Active Check

    private var isVaniActive: Bool {
        if viewModel.isLoading || viewModel.isStreaming { return true }
        guard viewModel.summary != nil else { return false }
        switch viewModel.vaniPlayer.playerState {
        case .fallback: return false
        default:        return true
        }
    }

    // MARK: - Summary Content

    private func summaryContent(_ content: String) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(parsedLines(content).enumerated()), id: \.offset) { _, line in
                    line.view
                        .textSelection(.enabled)
                }
            }
            .padding()
            .padding(.bottom, isVaniActive ? 88 : 0)
        }
    }

    private struct ParsedLine {
        let view: AnyView
    }

    private func parsedLines(_ content: String) -> [ParsedLine] {
        content
            .components(separatedBy: "\n")
            .compactMap { raw -> ParsedLine? in
                let trimmed = raw.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return nil }

                if trimmed.hasPrefix("###") {
                    let text = trimmed
                        .replacingOccurrences(of: "^#{1,6}\\s*", with: "", options: .regularExpression)
                    return ParsedLine(view: AnyView(
                        Text(text)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineSpacing(2)
                    ))
                }

                if let attributed = try? AttributedString(
                    markdown: trimmed,
                    options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                ) {
                    return ParsedLine(view: AnyView(
                        Text(attributed)
                            .font(.body)
                            .lineSpacing(4)
                    ))
                }

                return ParsedLine(view: AnyView(
                    Text(trimmed)
                        .font(.body)
                        .lineSpacing(4)
                ))
            }
    }

    // MARK: - Loading

    private var loadingContent: some View {
        VStack(spacing: 16) {
            Text(loadingMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 24)
            SummarySkeleton()
        }
    }

    // MARK: - Error

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
            .tint(Theme.Colors.primary)
            Spacer()
        }
        .padding()
    }

    // MARK: - Toolbar

    private var toolbarButtons: some View {
        Button {
            showingShareSheet = true
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .disabled(viewModel.summary == nil)
    }

    // MARK: - Share formatting

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
        .cornerRadius(Theme.CornerRadius.md)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                withAnimation { isShowing = false }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
