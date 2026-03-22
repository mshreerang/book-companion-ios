import SwiftUI

struct CharacterCardsGridView: View {
    let book: Book
    let chapter: Int
    let language: String
    let allBooks: [Book]

    @StateObject private var viewModel: CharacterCardsViewModel
    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss

    @State private var expandedName: String? = nil
    @State private var showPaywall = false

    private let columns = [
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0)
    ]

    init(book: Book, chapter: Int, language: String = "English", allBooks: [Book] = []) {
        self.book = book
        self.chapter = chapter
        self.language = language
        self.allBooks = allBooks
        self._viewModel = StateObject(wrappedValue: CharacterCardsViewModel(
            book: book,
            chapter: chapter,
            language: language,
            allBooks: allBooks
        ))
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if viewModel.isLoadingNames {
                loadingView
            } else if let limited = viewModel.limitedMessage {
                limitedView(limited)
            } else if let error = viewModel.error {
                errorView(error)
            } else if viewModel.names.isEmpty {
                emptyView
            } else {
                cardsGrid
            }

            if let name = expandedName {
                expandedOverlay(name: name)
            }
        }
        .navigationTitle("Characters")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .opacity(expandedName == nil ? 1 : 0)
            }
        }
        .task { await viewModel.loadNames() }
        // When isPro flips to true (after purchase or webhook sync),
        // clear the quota error and reload characters automatically.
        .onChange(of: store.isPro) { _, isPro in
            if isPro && (viewModel.error != nil || viewModel.limitedMessage != nil) {
                viewModel.error = nil
                viewModel.limitedMessage = nil
                Task { await viewModel.loadNames() }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(triggerReason: "Upgrade to Pro for unlimited character analyses.")
                .environmentObject(StoreManager.shared)
        }
    }

    // MARK: - Cards Grid

    private var cardsGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text("Safe up to Chapter \(chapter)")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.secondary.opacity(0.12))
                    .foregroundColor(Theme.Colors.secondary)
                    .cornerRadius(Theme.CornerRadius.sm)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(viewModel.names, id: \.self) { name in
                        CharacterCardFront(name: name)
                            .frame(height: 200)
                            .padding(8)
                            .opacity(expandedName == name ? 0 : 1)
                            .scaleEffect(expandedName == name ? 0.95 : 1)
                            .onTapGesture { selectCard(name: name) }
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical)
        }
        .scrollDisabled(expandedName != nil)
    }

    // MARK: - Expanded Overlay

    private func expandedOverlay(name: String) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismissCard() }
                .transition(.opacity)

            CharacterCardView(
                name: name,
                book: book,
                chapter: chapter,
                viewModel: viewModel,
                onDismiss: { dismissCard() }
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 60)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
        .zIndex(10)
    }

    // MARK: - Expand / Dismiss

    private func selectCard(name: String) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            expandedName = name
        }
    }

    private func dismissCard() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            expandedName = nil
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.5)
            Text("Loading characters…")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: message.contains("limit") || message.contains("Upgrade")
                  ? "exclamationmark.circle.fill"
                  : "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(message.contains("limit") ? .red : .orange)

            Text(message.contains("limit") ? "Character Limit Reached" : "Failed to load characters")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if message.contains("Upgrade") || message.contains("limit") {
                Button("Upgrade to Pro") { showPaywall = true }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.Colors.primary)
            } else {
                Button("Try Again") {
                    Task { await viewModel.loadNames() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.Colors.primary)
            }
        }
        .padding()
    }

    // MARK: - Limited Knowledge

    private func limitedView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("Characters Unavailable")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Try Again") {
                Task { await viewModel.loadNames() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.primary)
        }
        .padding()
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Characters Found")
                .font(.headline)
            Text("Try reading more chapters to discover characters")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// MARK: - Preview

#Preview {
    CharacterCardsGridView(
        book: Book(
            id: UUID(),
            title: "Harry Potter and the Goblet of Fire",
            author: "J.K. Rowling",
            language: .english,
            totalChapters: 37,
            coverImageURL: nil,
            createdAt: Date()
        ),
        chapter: 33
    )
    .environmentObject(StoreManager.shared)
}
