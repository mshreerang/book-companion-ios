//
//  ProgressInputVIew.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
import SwiftUI

struct ProgressInputView: View {

    let book: Book

    @State private var selectedLanguage: Language
    @State private var selectedChapter: Int = 1

    init(book: Book) {
        self.book = book
        _selectedLanguage = State(initialValue: book.language)
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Language")) {
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(Language.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("Progress")) {
                Stepper(
                    value: $selectedChapter,
                    in: 1...100,
                    step: 1
                ) {
                    Text("Last completed chapter: \(selectedChapter)")
                }
            }

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
    }
}

