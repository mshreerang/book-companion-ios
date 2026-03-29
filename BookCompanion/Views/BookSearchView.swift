import SwiftUI
import Combine

struct BookSearchView: View {

    @StateObject private var viewModel: BookSearchViewModel
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var bookManager: BookManager
    @State private var showingAddBook = false
    @State private var showingSettings = false
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    @State private var bannerMessage: String? = nil
    @State private var bannerStyle: BannerStyle = .success
    
    
    private let makeProgressViewModel: (Book) -> ProgressInputViewModel
    private let makeSummaryViewModel: (Book, Language, SummaryLength) -> SummaryViewModel
    private let makeCharactersViewModel: (Book, Language) -> CharactersViewModel

    init(
        viewModel: BookSearchViewModel,
        settingsManager: SettingsManager,
        bookManager: BookManager,
        makeProgressViewModel: @escaping (Book) -> ProgressInputViewModel,
        makeSummaryViewModel: @escaping (Book, Language, SummaryLength) -> SummaryViewModel,
        makeCharactersViewModel: @escaping (Book, Language) -> CharactersViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.settingsManager = settingsManager
        self.bookManager = bookManager
        self.makeProgressViewModel = makeProgressViewModel
        self.makeSummaryViewModel = makeSummaryViewModel
        self.makeCharactersViewModel = makeCharactersViewModel
    }

    // MARK: - Derived state

    private var isLibraryEmpty: Bool {
        viewModel.books.isEmpty && viewModel.searchText.isEmpty
    }

    private var filteredBooks: [Book] {
        guard !viewModel.searchText.isEmpty else { return viewModel.books }
        return viewModel.books.filter {
            $0.title.localizedCaseInsensitiveContains(viewModel.searchText) ||
            $0.author.localizedCaseInsensitiveContains(viewModel.searchText)
        }
    }

    // MARK: - Body

    var body: some View {
        // Wrap in a Group so we can conditionally attach .searchable
        Group {
            if isLibraryEmpty {
                // Empty library — clean slate, single CTA, no FAB, no search bar
                EmptyLibraryView(onAddBook: { showingAddBook = true })
            } else if filteredBooks.isEmpty {
                // Search returned nothing
                EmptySearchResultsView(searchQuery: viewModel.searchText)
            } else {
                bookList
            }
        }
        .navigationTitle("My Library")
        // Search bar only appears when there are books to search
        .if(!isLibraryEmpty) { view in
            view.searchable(text: $viewModel.searchText, prompt: "Search your library…")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                    AnalyticsManager.shared.track(event: "settings_opened")
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 16, weight: .medium))
                }
                .accessibleButton(
                    label: A11y.Library.settingsButton,
                    hint: A11y.Library.settingsButtonHint
                )
            }
        }
        .sheet(isPresented: $showingAddBook) {
            UnifiedSearchView()
                .environmentObject(bookManager)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(settingsManager: settingsManager)
        }
        .overlay(alignment: .top) {
            if let message = bannerMessage {
                NotificationBanner(
                    message: message,
                    style: bannerStyle,
                    onDismiss: { bannerMessage = nil }
                )
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: bannerMessage)
            }
        }
        .onChange(of: deepLinkManager.pendingLink) { _, link in
            guard let link else { return }
            switch link {
            case .search:
                showingAddBook = true
                deepLinkManager.consume()
            case .emailConfirmed, .resetPassword:
                break // handled in SignInView
            }
        }
        // FAB + mode badge — hidden on empty state
        .overlay(alignment: .bottomTrailing) {
            if !isLibraryEmpty {
                fabStack
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Book list

    private var bookList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredBooks) { book in
                    NavigationLink {
                        ProgressInputView(
                            viewModel: makeProgressViewModel(book),
                            makeSummaryViewModel: makeSummaryViewModel,
                            makeCharactersViewModel: makeCharactersViewModel
                        )
                        .onDisappear { bookManager.reloadProgress() }
                        .onAppear {
                            AnalyticsManager.shared.track(
                                event: "book_opened",
                                properties: ["book_title": book.title, "author": book.author]
                            )
                        }
                    } label: {
                        BookCard(book: book)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteBook(book)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 88) // clearance for FAB
        }
        .refreshable {
            await bookManager.syncFromCloud()
        }
    }

    // MARK: - FAB + mode badge

    private var fabStack: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Button {
                HapticManager.lightImpact()
                showingAddBook = true
                AnalyticsManager.shared.track(event: "add_book_button_tapped")
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Theme.Colors.brandGradient)
                    .clipShape(Circle())
                    .shadow(color: Theme.Colors.brandShadow, radius: 8, x: 0, y: 4)
            }
            .accessibleButton(
                label: A11y.Library.searchButton,
                hint: "Open book search"
            )

            modeBadge
        }
        .padding(20)
    }

    // MARK: - Mode badge
    // Uses brand teal for AI mode (not generic green), brand indigo for offline.

    private var modeBadge: some View {
        Text(settingsManager.settings.isAIEnabled ? "AI" : "Offline")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                settingsManager.settings.isAIEnabled
                    ? Theme.Colors.secondary   // teal
                    : Theme.Colors.primary     // indigo
            )
            .foregroundColor(.white)
            .cornerRadius(Theme.CornerRadius.sm)
    }

    // MARK: - Delete

    private func deleteBook(_ book: Book) {
        AnalyticsManager.shared.track(
            event: "book_deleted",
            properties: ["book_title": book.title, "author": book.author]
        )
        if let index = bookManager.books.firstIndex(where: { $0.id == book.id }) {
            bookManager.deleteBooks(at: IndexSet(integer: index))
        }
    }
}

// MARK: - Conditional modifier helper
// Allows .if(!condition) { view in view.searchable(...) }

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
