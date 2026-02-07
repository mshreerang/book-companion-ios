//
//  SearchBooksView.swift
//  BookCompanion
//
//  Created by Shree on 06/02/2026.
//

import SwiftUI

struct SearchBooksView: View {
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var bookManager: BookManager
    
    @State private var searchText = ""
    @State private var results: [BookSearchResult] = []
    @State private var isSearching = false
    @State private var searchError: Error?
    @State private var selectedBook: BookSearchResult?

    
    private let searchService = BookSearchService()
    
    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty && !isSearching && searchText.isEmpty {
                    // Initial state
                    ContentUnavailableView {
                        Label("Search for Books", systemImage: "magnifyingglass")
                    } description: {
                        Text("Search by title or author to find books")
                    }
                } else if isSearching {
                    // Loading
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Searching...")
                            .foregroundColor(.secondary)
                    }
                } else if let error = searchError {
                    // Error
                    ContentUnavailableView {
                        Label("Search Failed", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error.localizedDescription)
                    } actions: {
                        Button("Try Again") {
                            Task {
                                await performSearch()
                            }
                        }
                    }
                } else if results.isEmpty {
                    // No results
                    ContentUnavailableView.search(text: searchText)
                } else {
                    // Results
                    List {
                        ForEach(results) { result in
                            BookSearchResultRow(result: result)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedBook = result
                                    
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search books...")
            .onSubmit(of: .search) {
                Task {
                    await performSearch()
                }
            }
            .onChange(of: searchText) { oldValue, newValue in
                // Auto-search after 0.5 second delay
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if searchText == newValue && !newValue.isEmpty {
                        await performSearch()
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
    
    private func performSearch() async {
        guard !searchText.isEmpty else {
            results = []
            return
        }
        
        isSearching = true
        searchError = nil
        
        do {
            results = try await searchService.search(query: searchText)
            searchError = nil
        } catch {
            searchError = error
            results = []
        }
        
        isSearching = false
    }
}

// MARK: - Book Search Result Row

struct BookSearchResultRow: View {
    let result: BookSearchResult
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail with better error handling
            Group {
                if let thumbnailURLString = result.thumbnailURL,
                   let url = URL(string: thumbnailURLString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 50, height: 75)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                    .frame(width: 50, height: 75)
                    .clipped()
                    .cornerRadius(4)
                } else {
                    placeholderImage
                }
            }
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(result.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let pages = result.pageCount {
                        Label("\(pages) pages", systemImage: "book.pages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(result.detectedLanguage.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 50, height: 75)
            .cornerRadius(4)
            .overlay {
                Image(systemName: "book.closed")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
    }
}
// MARK: - Confirm Book View

struct ConfirmBookView: View {
    
    @Environment(\.dismiss) var dismiss
    let searchResult: BookSearchResult
    @ObservedObject var bookManager: BookManager
    let onConfirm: () -> Void
    
    @State private var totalChapters: Int
    @State private var selectedLanguage: Language
    
    init(
        searchResult: BookSearchResult,
        bookManager: BookManager,
        onConfirm: @escaping () -> Void
    ) {
        self.searchResult = searchResult
        self.bookManager = bookManager
        self.onConfirm = onConfirm
        
        // Initialize state
        _totalChapters = State(initialValue: searchResult.estimatedChapters)
        _selectedLanguage = State(initialValue: searchResult.detectedLanguage)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Book preview with thumbnail
                Section {
                    HStack(spacing: 12) {
                        if let thumbnailURLString = searchResult.thumbnailURL,
                           let url = URL(string: thumbnailURLString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                case .failure(_), .empty:
                                    placeholderImage
                                @unknown default:
                                    placeholderImage
                                }
                            }
                            .frame(width: 80, height: 120)
                            .cornerRadius(6)
                        } else {
                            placeholderImage
                                .frame(width: 80, height: 120)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(searchResult.title)
                                .font(.headline)
                            Text(searchResult.author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Details") {
                    if let pages = searchResult.pageCount {
                        LabeledContent("Pages", value: "\(pages)")
                    }
                }
                
                Section {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(Language.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    
                    Stepper("Total Chapters: \(totalChapters)", value: $totalChapters, in: 1...500)
                } header: {
                    Text("Customize")
                } footer: {
                    Text("We estimated \(searchResult.estimatedChapters) chapters based on page count. Adjust if needed.")
                }
                
                Section {
                    Button {
                        addBook()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Add to Library")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Confirm Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .cornerRadius(6)
            .overlay {
                Image(systemName: "book.closed")
                    .foregroundColor(.gray)
                    .font(.largeTitle)
            }
    }
    
    private func addBook() {
        bookManager.addBook(
            title: searchResult.title,
            author: searchResult.author,
            language: selectedLanguage,
            totalChapters: totalChapters,
            coverImageURL: searchResult.thumbnailURL            
        )
        
        dismiss()
        onConfirm()
    }
}

#Preview {
    SearchBooksView(bookManager: BookManager())
}

