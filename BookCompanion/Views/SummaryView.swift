import SwiftUI

struct SummaryView: View {

    @StateObject private var viewModel: SummaryViewModel
    let chapter: Int

    init(
        viewModel: SummaryViewModel,
        chapter: Int
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.chapter = chapter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Safe up to Chapter \(chapter)")
                .font(.caption)
                .padding(6)
                .background(Color.green.opacity(0.15))
                .cornerRadius(6)
            if viewModel.isCached {
                Text("Previously generated")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
            HStack {
                Spacer()

                Button {
                    Task {
                        await viewModel.regenerate(chapter: chapter)
                    }
                } label: {
                    Text("Regenerate summary")
                        .font(.caption)
                }
                .disabled(viewModel.isLoading)

                Spacer()
            }

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
        .task(id: chapter) {
            await viewModel.generate(chapter: chapter)
        }
    }
}
