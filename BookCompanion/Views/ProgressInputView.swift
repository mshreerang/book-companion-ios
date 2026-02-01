import SwiftUI

struct ProgressInputView: View {

    let book: Book

    @State private var hasLoadedInitialState = false
    @State private var selectedLanguage: Language
    @State private var selectedChapter: Int = 1

    private let progressStore = ProgressStore.shared

    init(book: Book) {
        self.book = book

        if let saved = ProgressStore.shared.load(bookId: book.id) {
            _selectedLanguage = State(initialValue: saved.language)
            _selectedChapter = State(initialValue: saved.chapter)
        } else {
            _selectedLanguage = State(initialValue: book.language)
            _selectedChapter = State(initialValue: 1)
        }
    }

    var body: some View {
        Form {

            // Book header
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Language selection
            Section(header: Text("Language")) {
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(Language.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedLanguage) {
                    guard hasLoadedInitialState else { return }

                    saveProgress()
                }
            }

            // Chapter progress
            Section(header: Text("Progress")) {
                Stepper(
                    value: $selectedChapter,
                    in: 1...100,
                    step: 1
                ) {
                    Text("Last completed chapter: \(selectedChapter)")
                }
                .onChange(of: selectedChapter) {
                    guard hasLoadedInitialState else { return }

                    saveProgress()
                }
            }

            // Action
            Section {
                NavigationLink {
                    SummaryView(
                        book: book,
                        language: selectedLanguage,
                        chapter: selectedChapter
                    )
                } label: {
                    Text("Summarise so far")
                        .fontWeight(.semibold)
                }
            }
        }
        .navigationTitle("Book Details")
        .onAppear {
            hasLoadedInitialState = true
        }
    }

    private func saveProgress() {
        let progress = ReadingProgress(
            id: UUID(),
            bookId: book.id,
            chapter: selectedChapter,
            language: selectedLanguage,
            updatedAt: Date()
        )

        progressStore.save(progress)
    }
}

