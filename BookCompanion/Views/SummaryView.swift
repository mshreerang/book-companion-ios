//
//  SummaryView.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
import SwiftUI


struct SummaryView: View {

    let book: Book
    let language: Language
    let chapter: Int

    @StateObject private var viewModel =
        SummaryViewModel(generator: MockSummaryGenerator())


    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Safety badge
            Text("Safe up to Chapter \(chapter)")
                .font(.caption)
                .padding(6)
                .background(Color.green.opacity(0.15))
                .cornerRadius(6)

            if viewModel.isLoading {
                Spacer()
                ProgressView("Preparing your summary…")
                Spacer()
            } else if let summary = viewModel.summary {
                ScrollView {
                    Text(summary.content)
                        .font(.body)
                        .padding(.top, 8)
                }

                Spacer()

                NavigationLink {
                    CharactersView(
                        characters: viewModel.characters,
                        chapter: chapter
                    )
                } label: {
                    Text("Characters")
                        .fontWeight(.semibold)
                }
            }

        }
        .padding()
        .navigationTitle("Story So Far")
        .task {
            await viewModel.generate(book: book, chapter: chapter)
        }
    }
}
