import SwiftUI

struct ProgressInputView: View {

    @StateObject private var viewModel: ProgressInputViewModel
    private let makeSummaryViewModel: (Book, Language, SummaryLength) -> SummaryViewModel  // ✅ Add length parameter
    private let makeCharactersViewModel: (Book, Language) -> CharactersViewModel

    init(
        viewModel: ProgressInputViewModel,
        makeSummaryViewModel: @escaping (Book, Language, SummaryLength) -> SummaryViewModel,  // ✅ Updated
        makeCharactersViewModel: @escaping (Book, Language) -> CharactersViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeSummaryViewModel = makeSummaryViewModel
        self.makeCharactersViewModel = makeCharactersViewModel 
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
                    in: 1...viewModel.book.totalChapters
                ) {
                    Text("Last completed chapter: \(viewModel.selectedChapter)")
                }
                .onChange(of: viewModel.selectedChapter) {
                    viewModel.updateChapter(viewModel.selectedChapter)
                }
            }
            
            // ✅ NEW: Summary length selection
            Section(header: Text("Summary Length")) {
                Picker("Length", selection: $viewModel.selectedLength) {
                    ForEach(SummaryLength.allCases) { length in
                        Text(length.displayName).tag(length)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.selectedLength) {
                    viewModel.updateLength(viewModel.selectedLength)
                }
            }

            // Action
            Section {
                // Summarise Story button
                NavigationLink {
                    SummaryView(
                        viewModel: makeSummaryViewModel(
                            viewModel.book,
                            viewModel.selectedLanguage,
                            viewModel.selectedLength
                        ),
                        chapter: viewModel.selectedChapter
                    )
                    .id(viewModel.selectedChapter)
                } label: {
                    HStack {
                        Image(systemName: "book.pages")
                        Text("Summarise Story")
                            .fontWeight(.semibold)
                    }
                }
                
                // View Characters button
                NavigationLink {
                    CharactersLoadingView(
                        viewModel: makeCharactersViewModel(
                            viewModel.book,
                            viewModel.selectedLanguage
                        ),
                        chapter: viewModel.selectedChapter,
                        length: viewModel.selectedLength
                    )
                } label: {
                    HStack {
                        Image(systemName: "person.2")
                        Text("View Characters")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .navigationTitle("Book Details")
        .onDisappear {
            viewModel.saveOnExit()
        }
    }
}
