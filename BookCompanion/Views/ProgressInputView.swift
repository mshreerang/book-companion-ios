import SwiftUI

struct ProgressInputView: View {

    @StateObject private var viewModel: ProgressInputViewModel
    private let makeSummaryViewModel: (Book) -> SummaryViewModel

    init(
        viewModel: ProgressInputViewModel,
        makeSummaryViewModel: @escaping (Book) -> SummaryViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeSummaryViewModel = makeSummaryViewModel
    }

    var body: some View {
        Form {

            // Book header
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.book.title)
                        .font(.headline)
                    Text(viewModel.book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Language selection
            Section(header: Text("Language")) {
                Picker("Language", selection: $viewModel.selectedLanguage) {
                    ForEach(Language.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.selectedLanguage) {
                    viewModel.updateLanguage(viewModel.selectedLanguage)
                }
            }

            // Chapter progress
            Section(header: Text("Progress")) {
                Stepper(
                    value: $viewModel.selectedChapter,
                    in: 1...100
                ) {
                    Text("Last completed chapter: \(viewModel.selectedChapter)")
                }
                .onChange(of: viewModel.selectedChapter) {
                    viewModel.updateChapter(viewModel.selectedChapter)
                }
            }

            // Action
            Section {
                NavigationLink {
                    SummaryView(
                        viewModel: makeSummaryViewModel(viewModel.book),
                        chapter: viewModel.selectedChapter
                    )
                    .id(viewModel.selectedChapter)
                } label: {
                    Text("Summarise so far")
                        .fontWeight(.semibold)
                }
            }
        }
        .navigationTitle("Book Details")
        .onDisappear {
            viewModel.saveOnExit()
        }
    }
}
