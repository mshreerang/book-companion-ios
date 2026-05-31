//
//  SearchBooksView.swift
//  BookCompanion
//
//  Created by Shree on 06/02/2026.
//  Updated: ConfirmBookView chapter input now uses TextField + stepper
//           (same pattern as AddBookView) so users aren't forced to
//           tap a Stepper 40+ times for longer books.
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
                    ContentUnavailableView {
                        Label("Search for Books", systemImage: "magnifyingglass")
                    } description: {
                        Text("Search by title or author to find books")
                    }
                } else if isSearching {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Searching…")
                            .foregroundColor(.secondary)
                    }
                } else if let error = searchError {
                    ContentUnavailableView {
                        Label("Search Failed", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error.localizedDescription)
                    } actions: {
                        Button("Try Again") {
                            Task { await performSearch() }
                        }
                    }
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    let bestMatches  = results.filter { $0.section == "bestMatch" }
                    let otherResults = results.filter { $0.section == "otherResults" }

                    List {
                        if !bestMatches.isEmpty {
                            Section("Best Match") {
                                ForEach(bestMatches) { result in
                                    BookSearchResultRow(result: result)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedBook = result }
                                }
                            }
                        }
                        if !otherResults.isEmpty {
                            Section("Other Results") {
                                ForEach(otherResults) { result in
                                    BookSearchResultRow(result: result)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedBook = result }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .searchable(text: $searchText, prompt: "Search books…")
            .onSubmit(of: .search) {
                Task { await performSearch() }
            }
            .onChange(of: searchText) { oldValue, newValue in
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
        guard !searchText.isEmpty else { results = []; return }
        isSearching = true
        searchError = nil
        do {
            results = try await searchService.search(query: searchText)
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
            Group {
                if let urlString = result.thumbnailURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            placeholderImage
                        }
                    }
                    .frame(width: 50, height: 75)
                    .clipped()
                    .cornerRadius(Theme.CornerRadius.xs)
                } else {
                    placeholderImage
                }
            }

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
            .fill(Color(.systemGray5))
            .frame(width: 50, height: 75)
            .cornerRadius(Theme.CornerRadius.xs)
            .overlay {
                Image(systemName: "book.closed")
                    .foregroundColor(.secondary)
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
    @State private var chaptersText: String
    @State private var selectedLanguage: Language

    // Series detection state
    @State private var detectedSeries: SeriesDetectionResult? = nil
    @State private var authorHint: AuthorSeriesHint? = nil
    @State private var seriesConfirmed: Bool = false
    @State private var seriesName: String = ""
    @State private var seriesPosition: Int = 1
    @State private var isScanning: Bool = false

    init(
        searchResult: BookSearchResult,
        bookManager: BookManager,
        onConfirm: @escaping () -> Void
    ) {
        self.searchResult = searchResult
        self.bookManager = bookManager
        self.onConfirm = onConfirm

        let estimated = searchResult.estimatedChapters
        _totalChapters   = State(initialValue: estimated)
        _chaptersText    = State(initialValue: "\(estimated)")
        _selectedLanguage = State(initialValue: searchResult.detectedLanguage)

        let detected = SeriesDetector.detect(from: searchResult)
        let hint = detected == nil
            ? SeriesDetector.authorHint(for: searchResult, in: bookManager.books)
            : nil

        _detectedSeries  = State(initialValue: detected)
        _authorHint      = State(initialValue: hint)

        let hasStrongSignal = detected != nil && !(detected?.seriesName.isEmpty ?? true)
        _seriesConfirmed = State(initialValue: hasStrongSignal)
        _seriesName      = State(initialValue: detected?.seriesName ?? "")
        _seriesPosition  = State(initialValue: detected?.position ?? (hint?.suggestedPosition ?? 1))

        _isScanning = State(initialValue: detected == nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Book preview
                Section {
                    HStack(spacing: 12) {
                        if let urlString = searchResult.thumbnailURL,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fit)
                                default:
                                    placeholderImage
                                }
                            }
                            .frame(width: 80, height: 120)
                            .cornerRadius(Theme.CornerRadius.sm)
                        } else {
                            placeholderImage.frame(width: 80, height: 120)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(searchResult.title).font(.headline)
                            Text(searchResult.author).font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(Language.allCases) { Text($0.displayName).tag($0) }
                    }

                    // Updated: TextField for direct entry + stepper for ±1 fine-tuning.
                    // Matches AddBookView — consistent pattern throughout the app.
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Total Chapters")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            TextField("e.g. 38", text: $chaptersText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 72)
                                .onChange(of: chaptersText) { _, newValue in
                                    let digits = newValue.filter(\.isNumber)
                                    if let n = Int(digits), n > 0 {
                                        totalChapters = min(n, 500)
                                        chaptersText  = "\(totalChapters)"
                                    } else if digits.isEmpty {
                                        chaptersText = ""
                                    }
                                }
                        }

                        Stepper(
                            "Adjust: \(totalChapters)",
                            value: $totalChapters,
                            in: 1...500
                        )
                        .onChange(of: totalChapters) { _, newValue in
                            chaptersText = "\(newValue)"
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Book Details")
                } footer: {
                    if let pages = searchResult.pageCount {
                        Text("Based on \(pages) pages, we suggest \(searchResult.estimatedChapters) chapters. Please enter the actual chapter count from your edition.")
                    } else {
                        Text("Enter the total number of chapters in your copy of the book.")
                    }
                }

                // Series section
                Section {
                    Toggle(isOn: $seriesConfirmed) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("Part of a Series").font(.subheadline)
                                if isScanning { ProgressView().scaleEffect(0.7) }
                            }
                            if isScanning {
                                Text("Scanning…").font(.caption).foregroundColor(.secondary)
                            } else if detectedSeries != nil, seriesConfirmed {
                                Text("Detected automatically").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(isScanning)
                    .onChange(of: seriesConfirmed) { _, confirmed in
                        if confirmed && seriesName.isEmpty {
                            seriesName = detectedSeries?.seriesName ?? ""
                            seriesPosition = detectedSeries?.position ?? 1
                        }
                    }

                    if seriesConfirmed {
                        TextField("Series Name", text: $seriesName).textFieldStyle(.plain)
                        Stepper("Book \(seriesPosition) in series", value: $seriesPosition, in: 1...50)
                    }
                } header: {
                    Text("Series")
                } footer: {
                    if isScanning {
                        Text("Checking series information…").foregroundColor(.secondary)
                    } else if seriesConfirmed {
                        Text("BookCompanion will use your series history for richer, context-aware summaries.")
                    } else if detectedSeries != nil {
                        Text("We detected this may be part of a series. Toggle to link it.")
                    } else if let hint = authorHint {
                        Text("You have \(hint.matchingBooks.count) other book(s) by this author. Toggle to link them as a series.")
                    }
                }

                Section {
                    Button {
                        addBook()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Add to Library").fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Confirm Book")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: searchResult.id) {
                guard isScanning else { return }
                let result = await SeriesManager.shared.detectSeries(
                    title: searchResult.title,
                    author: searchResult.author
                )
                isScanning = false
                if let result {
                    detectedSeries = result
                    seriesName = result.seriesName
                    seriesPosition = result.position
                    seriesConfirmed = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .cornerRadius(Theme.CornerRadius.sm)
            .overlay {
                Image(systemName: "book.closed")
                    .foregroundColor(.secondary)
                    .font(.largeTitle)
            }
    }

    private func addBook() {
        bookManager.addBook(
            title: searchResult.title,
            author: searchResult.author,
            language: selectedLanguage,
            totalChapters: totalChapters,
            pageCount: searchResult.pageCount,
            coverImageURL: searchResult.thumbnailURL,
            bookType: searchResult.bookType,
            seriesName: seriesConfirmed && !seriesName.isEmpty ? seriesName : nil,
            seriesPosition: seriesConfirmed ? seriesPosition : nil
        )
        dismiss()
        onConfirm()
    }
}

#Preview {
    SearchBooksView(bookManager: BookManager())
}
