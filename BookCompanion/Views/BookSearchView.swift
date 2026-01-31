import SwiftUI

struct BookSearchView: View {

    @ObservedObject private var viewModel = BookSearchViewModel()

    private var filteredBooks: [Book] {
        guard !viewModel.searchText.isEmpty else {
            return viewModel.results
        }

        return viewModel.results.filter {
            $0.title.localizedCaseInsensitiveContains(viewModel.searchText) ||
            $0.author.localizedCaseInsensitiveContains(viewModel.searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredBooks) { book in
                NavigationLink {
                    ProgressInputView(book: book)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(.headline)

                        Text(book.author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Select Book")
        .searchable(
            text: $viewModel.searchText,
            prompt: "Search by title or author"
        )
    }
}
