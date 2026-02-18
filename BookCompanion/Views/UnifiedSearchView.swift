//
//  UnifiedSearchView.swift
//  BookCompanion
//
//  Created on 15/02/2026.
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
                
                // Search Bar with Button
                searchHeader
                
                // Results
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedBook) { book in
                ConfirmBookView(
                    searchResult: book,
                    bookManager: bookManager,
                    onConfirm: {
                        selectedBook = nil
                        dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Search Header
    
    private var searchHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Search TextField
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search books...", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .submitLabel(.search)
                        .onSubmit {
                            performOnlineSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.clearOnlineResults()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Search Button
                Button(action: performOnlineSearch) {
                    if isSearching {
                        ProgressView()
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(searchText.isEmpty ? .gray : .blue)
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
                
                // Library Results (Instant Filter)
                if !libraryResults.isEmpty {
                    librarySection
                }
                
                // Online Results (After Search Button)
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
                Button(action: {
                    dismiss()
                }) {
                    LibraryBookRow(book: book)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .padding(.top, 12)
        }
    }
    
    // MARK: - Online Section
    
    private var onlineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🌐 Add More Books (\(viewModel.onlineResults.count))")
                .font(.headline)
                .padding(.horizontal, 16)
            
            if isSearching {
                // Loading state
                VStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        HStack(spacing: 12) {
                            // Skeleton thumbnail
                            Rectangle()
                                .fill(Color(UIColor.systemGray5))
                                .frame(width: 50, height: 75)
                                .cornerRadius(6)
                            
                            // Skeleton info
                            VStack(alignment: .leading, spacing: 6) {
                                Rectangle()
                                    .fill(Color(UIColor.systemGray5))
                                    .frame(height: 16)
                                    .frame(maxWidth: 200)
                                Rectangle()
                                    .fill(Color(UIColor.systemGray5))
                                    .frame(height: 14)
                                    .frame(maxWidth: 150)
                                Rectangle()
                                    .fill(Color(UIColor.systemGray5))
                                    .frame(height: 12)
                                    .frame(maxWidth: 100)
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
                ForEach(viewModel.onlineResults) { book in
                    OnlineBookRow(
                        book: book,
                        isAdded: bookManager.books.contains(where: { $0.title == book.title && $0.author == book.author })
                    ) {
                        HapticManager.lightImpact()
                        selectedBook = book
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
    
    // MARK: - Helper Views
    
    struct LibraryBookRow: View {
        let book: Book
        
        var body: some View {
            HStack(spacing: 16) {
                // Book Cover
                if let coverURL = book.coverImageURL {
                    CachedCoverImage(bookId: book.id, coverURL: coverURL)
                        .frame(width: 50, height: 75)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 50, height: 75)
                        .cornerRadius(6)
                        
                        Image(systemName: "book.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
                
                // Book Info
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
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
    
    struct OnlineBookRow: View {
        let book: BookSearchResult
        let isAdded: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    // Book Cover Thumbnail
                    if let thumbnailURL = book.thumbnailURL {
                        AsyncImage(url: URL(string: thumbnailURL)) { phase in
                            switch phase {
                            case .empty:
                                placeholderCover
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 75)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            case .failure(_):
                                placeholderCover
                            @unknown default:
                                placeholderCover
                            }
                        }
                    } else {
                        placeholderCover
                    }
                    
                    // Book Info
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
                    
                    // Add Button or Added Indicator
                    if isAdded {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Added")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                .padding(16)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
        }
        
        private var placeholderCover: some View {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.title3)
            }
            .frame(width: 50, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    // MARK: - Computed Properties
    
    private var libraryResults: [Book] {
        if searchText.isEmpty {
            return []
        }
        
        // Instant filter of library (no API call)
        return bookManager.books.filter { book in
            book.title.localizedCaseInsensitiveContains(searchText) ||
            book.author.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Actions
    
    private func performOnlineSearch() {
        guard !searchText.isEmpty else { return }
        
        HapticManager.mediumImpact()
        
        isSearching = true
        
        Task {
            await viewModel.searchOnline(query: searchText)
            isSearching = false
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
            let results = try await searchService.search(query: query)
            onlineResults = results
        } catch {
            errorMessage = error.localizedDescription
            onlineResults = []
        }
    }
    
    func clearOnlineResults() {
        onlineResults = []
        hasSearched = false
        errorMessage = nil
    }
}
