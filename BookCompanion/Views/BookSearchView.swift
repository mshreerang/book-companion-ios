import SwiftUI
import Combine

struct BookSearchView: View {

    @StateObject private var viewModel: BookSearchViewModel
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var bookManager: BookManager  // ✅ Add this
    @State private var showingAddBook = false  // ✅ Add this
    
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

    private var filteredBooks: [Book] {
        guard !viewModel.searchText.isEmpty else {
            return viewModel.books
        }

        return viewModel.books.filter {
            $0.title.localizedCaseInsensitiveContains(viewModel.searchText) ||
            $0.author.localizedCaseInsensitiveContains(viewModel.searchText)
        }
    }

    var body: some View {
        Group {
            if filteredBooks.isEmpty && viewModel.searchText.isEmpty {
                // Empty state - no books at all
                ContentUnavailableView {
                    Label("No Books Yet", systemImage: "book.closed")
                } description: {
                    Text("Add your first book to get started")
                } actions: {
                    Button {
                        showingAddBook = true
                    } label: {
                        Text("Add Book")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if filteredBooks.isEmpty {
                // Empty state - search found nothing
                ContentUnavailableView.search
            } else {
                // Show books
                // Results
                List {
                    ForEach(filteredBooks) { book in
                        NavigationLink {
                            ProgressInputView(
                                viewModel: makeProgressViewModel(book),
                                makeSummaryViewModel: makeSummaryViewModel,
                                makeCharactersViewModel: makeCharactersViewModel
                            )
                        } label: {
                            HStack(spacing: 12) {
                                // Book Cover
                                if let coverURL = book.coverImageURL,
                                   let url = URL(string: coverURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        case .empty:
                                            placeholderCover
                                        case .failure(_):
                                            placeholderCover
                                        @unknown default:
                                            placeholderCover
                                        }
                                    }
                                    .frame(width: 60, height: 90)
                                    .cornerRadius(6)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                } else {
                                    placeholderCover
                                        .frame(width: 60, height: 90)
                                }
                                
                                // Book Info
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(book.title)
                                        .font(.headline)
                                        .lineLimit(2)
                                    
                                    Text(book.author)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 8) {
                                        Label(book.chaptersInfo, systemImage: "book.pages")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Text(book.language.displayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        bookManager.deleteBooks(at: indexSet)
                    }
                }
            }
        }
        .navigationTitle("My Library")
        .searchable(
            text: $viewModel.searchText,
            prompt: "Search by title or author"
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingAddBook = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    SettingsView(settingsManager: settingsManager)
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingAddBook) {
            SearchBooksView(bookManager: bookManager)
        }
        .overlay(alignment: .bottomTrailing) {
            // Mode badge
            if settingsManager.settings.isAIEnabled {
                Label("AI", systemImage: "sparkles")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(8)
                    .padding()
            } else {
                Label("Offline", systemImage: "airplane")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                    .padding()
            }
        }
    }
    private var placeholderCover: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .cornerRadius(6)
            .overlay {
                Image(systemName: "book.closed.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}
