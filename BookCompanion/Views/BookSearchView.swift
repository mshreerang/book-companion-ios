import SwiftUI
import Combine

struct BookSearchView: View {

    @StateObject private var viewModel: BookSearchViewModel
    private let makeProgressViewModel: (Book) -> ProgressInputViewModel
    private let makeSummaryViewModel: (Book, Language) -> SummaryViewModel

    init(
        viewModel: BookSearchViewModel,
        makeProgressViewModel: @escaping (Book) -> ProgressInputViewModel,
        makeSummaryViewModel: @escaping (Book, Language) -> SummaryViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeProgressViewModel = makeProgressViewModel
        self.makeSummaryViewModel = makeSummaryViewModel
    }

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
                    ProgressInputView(
                        viewModel: makeProgressViewModel(book),
                        makeSummaryViewModel: makeSummaryViewModel
                    )
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
