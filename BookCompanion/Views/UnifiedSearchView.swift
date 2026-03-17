//
//  UnifiedSearchView.swift
//  BookCompanion
//
//  Created on 15/02/2026.
//  Updated: LibraryBookRow and OnlineBookRow placeholder covers use
//           Theme brand gradient instead of hardcoded blue/purple.
//           "+" add button and search arrow use Theme.Colors.primary.
//
import SwiftUI
import Combine

struct UnifiedSearchView: View {

    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = UnifiedSearchViewModel()
    @EnvironmentObject var bookManager: BookManager

    @State private var searchText = ""
    @State private var isSearching = false
    @State private var selectedBook: BookSearchResult?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchHeader

                if searchText.isEmpty {
                    emptySearchState
                } else {
                    searchResults
                }
            }
            .navigationTitle("Search Books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $selectedBook) { book in
                ConfirmBookView(
                    searchResult: book,
                    bookManager: bookManager,
                    onConfirm: {
                        AnalyticsManager.shared.track(
                            event: "book_added",
                            properties: [
                                "book_title": book.title,
                                "author": book.author,
                                "source": "online_search"
                            ]
                        )
                        selectedBook = nil
                        dismiss()
                    }
                )
            }
            .onAppear {
                AnalyticsManager.shared.track(event: "book_search_opened")
            }
        }
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search books…", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .submitLabel(.search)
                        .onSubmit { performOnlineSearch() }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            viewModel.clearOnlineResults()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(Theme.CornerRadius.lg)

                // Search arrow — updated: Theme.Colors.primary instead of .blue
                Button(action: performOnlineSearch) {
                    if isSearching {
                        ProgressView()
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(searchText.isEmpty
                                             ? .gray
                                             : Theme.Colors.primary)
                    }
                }
                .disabled(searchText.isEmpty || isSearching)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }

    // MARK: - Empty State

    private var emptySearchState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Search for Books")
                .font(.title3)

            Text("Type a book title or author name\nand tap search to find books")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Search Results

    private var searchResults: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !libraryResults.isEmpty {
                    librarySection
                }
                if viewModel.hasSearched {
                    onlineSection
                }
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Library Section

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📚 In Your Library (\(libraryResults.count))")
                .font(.headline)
                .padding(.horizontal, 16)

            ForEach(libraryResults) { book in
                Button { dismiss() } label: {
                    LibraryBookRow(book: book)
                }
                .buttonStyle(.plain)
            }

            Divider().padding(.top, 12)
        }
    }

    // MARK: - Online Section

    private var onlineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🌐 Add More Books (\(viewModel.onlineResults.count))")
                .font(.headline)
                .padding(.horizontal, 16)

            if isSearching {
                // Skeleton loading
                VStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(Color(UIColor.systemGray5))
                                .frame(width: 50, height: 75)
                                .cornerRadius(Theme.CornerRadius.sm)

                            VStack(alignment: .leading, spacing: 6) {
                                Rectangle().fill(Color(UIColor.systemGray5)).frame(height: 16).frame(maxWidth: 200)
                                Rectangle().fill(Color(UIColor.systemGray5)).frame(height: 14).frame(maxWidth: 150)
                                Rectangle().fill(Color(UIColor.systemGray5)).frame(height: 12).frame(maxWidth: 100)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            } else if viewModel.onlineResults.isEmpty {
                noOnlineResultsView
            } else {
                let bestMatches  = viewModel.onlineResults.filter { $0.section == "bestMatch" }
                let otherResults = viewModel.onlineResults.filter { $0.section == "otherResults" }

                if !bestMatches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⭐ Best Match")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)

                        ForEach(bestMatches) { book in
                            OnlineBookRow(
                                book: book,
                                isAdded: bookManager.books.contains {
                                    $0.title == book.title && $0.author == book.author
                                }
                            ) {
                                HapticManager.lightImpact()
                                selectedBook = book
                            }
                        }
                    }
                }

                if !otherResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Other Results")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, bestMatches.isEmpty ? 0 : 8)

                        ForEach(otherResults) { book in
                            OnlineBookRow(
                                book: book,
                                isAdded: bookManager.books.contains {
                                    $0.title == book.title && $0.author == book.author
                                }
                            ) {
                                HapticManager.lightImpact()
                                selectedBook = book
                            }
                        }
                    }
                }
            }
        }
    }

    private var noOnlineResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No books found")
                .font(.headline)
            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }

    // MARK: - Library Book Row

    struct LibraryBookRow: View {
        let book: Book

        var body: some View {
            HStack(spacing: 16) {
                if let coverURL = book.coverImageURL {
                    CachedCoverImage(bookId: book.id, coverURL: coverURL)
                        .frame(width: 50, height: 75)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                } else {
                    // Updated: Theme brand gradient instead of hardcoded blue/purple
                    ZStack {
                        Theme.Colors.brandGradientDiagonal
                            .opacity(0.7)
                        Image(systemName: "book.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                    .frame(width: 50, height: 75)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(book.totalChapters) chapters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(Theme.CornerRadius.lg)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Online Book Row

    struct OnlineBookRow: View {
        let book: BookSearchResult
        let isAdded: Bool
        let onTap: () -> Void

        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    if let thumbnailURL = book.thumbnailURL {
                        AsyncImage(url: URL(string: thumbnailURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 75)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                            default:
                                placeholderCover
                            }
                        }
                    } else {
                        placeholderCover
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(.headline)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if let pageCount = book.pageCount {
                            Text("\(pageCount) pages")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if isAdded {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.Colors.secondary)
                            Text("Added")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondary)
                        }
                    } else {
                        // Updated: Theme.Colors.primary instead of .blue
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
                .padding(16)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(Theme.CornerRadius.lg)
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
        }

        private var placeholderCover: some View {
            // Updated: Theme brand gradient instead of hardcoded blue/purple
            ZStack {
                Theme.Colors.brandGradientDiagonal
                    .opacity(0.4)
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.title3)
            }
            .frame(width: 50, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
        }
    }

    // MARK: - Computed Properties

    private var libraryResults: [Book] {
        guard !searchText.isEmpty else { return [] }
        return bookManager.books.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Actions

    private func performOnlineSearch() {
        guard !searchText.isEmpty else { return }

        AnalyticsManager.shared.track(
            event: "book_search_performed",
            properties: ["query": searchText, "query_length": searchText.count]
        )

        HapticManager.mediumImpact()
        isSearching = true

        Task {
            await viewModel.searchOnline(query: searchText)
            isSearching = false

            AnalyticsManager.shared.track(
                event: "book_search_completed",
                properties: ["query": searchText, "results_count": viewModel.onlineResults.count]
            )
        }
    }
}

// MARK: - ViewModel

@MainActor
class UnifiedSearchViewModel: ObservableObject {

    @Published var onlineResults: [BookSearchResult] = []
    @Published var hasSearched = false
    @Published var errorMessage: String?

    private let searchService = BookSearchService()

    func searchOnline(query: String) async {
        hasSearched = true
        errorMessage = nil

        do {
            onlineResults = try await searchService.search(query: query)
        } catch {
            errorMessage = error.localizedDescription
            onlineResults = []

            AnalyticsManager.shared.track(
                event: "book_search_failed",
                properties: ["query": query, "error": error.localizedDescription]
            )
        }
    }

    func clearOnlineResults() {
        onlineResults = []
        hasSearched = false
        errorMessage = nil
    }
}
