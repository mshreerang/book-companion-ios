import SwiftUI
import Combine

struct BookSearchView: View {

    @StateObject private var viewModel: BookSearchViewModel
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var bookManager: BookManager
    @State private var showingAddBook = false
    @State private var showingSettings = false
    
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

    // ✅ Simplified filter - broken into separate steps
    private var filteredBooks: [Book] {
        let searchText = viewModel.searchText
        let allBooks = viewModel.books
        
        guard !searchText.isEmpty else {
            return allBooks
        }

        return allBooks.filter { book in
            let matchesTitle = book.title.localizedCaseInsensitiveContains(searchText)
            let matchesAuthor = book.author.localizedCaseInsensitiveContains(searchText)
            return matchesTitle || matchesAuthor
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if filteredBooks.isEmpty && viewModel.searchText.isEmpty {
                // Empty state - no books at all
                EmptyLibraryView(onAddBook: {
                    showingAddBook = true
                })
            } else if filteredBooks.isEmpty {
                // Empty state - search found nothing
                ContentUnavailableView.search
            } else {
                // Show books in card layout
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredBooks) { book in
                            NavigationLink {
                                ProgressInputView(
                                    viewModel: makeProgressViewModel(book),
                                    makeSummaryViewModel: makeSummaryViewModel,
                                    makeCharactersViewModel: makeCharactersViewModel
                                )
                                .onDisappear {
                                    bookManager.reloadProgress()
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
                    .padding(.bottom, 80) // Space for FAB
                }
            }
        }
        .navigationTitle("My Library")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
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
        .overlay(alignment: .bottomTrailing) {
            fabButton
        }
    }
    
    // ✅ Extracted FAB to separate computed property
    private var fabButton: some View {
        VStack(alignment: .trailing, spacing: 12) {
            // Floating Action Button (FAB)
            Button(action: {
                HapticManager.lightImpact()
                showingAddBook = true
            }) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .accessibleButton(
                label: A11y.Library.searchButton,
                hint: "Open book search"
            )
            
            // Mode badge
            modeBadge
        }
        .padding(20)
    }
    
    // ✅ Extracted mode badge to separate computed property
    private var modeBadge: some View {
        Group {
            if settingsManager.settings.isAIEnabled {
                Text("AI")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            } else {
                Text("Offline")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
    
    // ✅ Extracted delete logic
    private func deleteBook(_ book: Book) {
        if let index = bookManager.books.firstIndex(where: { $0.id == book.id }) {
            bookManager.deleteBooks(at: IndexSet(integer: index))
        }
    }
}
