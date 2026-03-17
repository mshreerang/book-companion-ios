import SwiftUI

struct ProgressInputView: View {

    @StateObject private var viewModel: ProgressInputViewModel
    private let makeSummaryViewModel: (Book, Language, SummaryLength) -> SummaryViewModel
    private let makeCharactersViewModel: (Book, Language) -> CharactersViewModel

    // Save confirmation toast — pure UI state, zero ViewModel involvement
    @State private var showSavedToast = false

    init(
        viewModel: ProgressInputViewModel,
        makeSummaryViewModel: @escaping (Book, Language, SummaryLength) -> SummaryViewModel,
        makeCharactersViewModel: @escaping (Book, Language) -> CharactersViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeSummaryViewModel = makeSummaryViewModel
        self.makeCharactersViewModel = makeCharactersViewModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {

                    CompactBookHeader(book: viewModel.book)

                    CompactChapterSelector(
                        selectedChapter: $viewModel.selectedChapter,
                        totalChapters: viewModel.book.totalChapters,
                        onChapterChange: { viewModel.updateChapter($0) }
                    )

                    ActionButtonPair(
                        book: viewModel.book,
                        chapter: viewModel.selectedChapter,
                        language: viewModel.selectedLanguage,
                        length: viewModel.selectedLength,
                        makeSummaryViewModel: makeSummaryViewModel,
                        makeCharactersViewModel: makeCharactersViewModel,
                        onAction: {
                            viewModel.syncChapterToCloud()
                            showSaveToast()
                        }
                    )

                    SettingsSection(
                        selectedLanguage: $viewModel.selectedLanguage,
                        selectedLength: $viewModel.selectedLength,
                        onLanguageChange: { viewModel.updateLanguage($0) },
                        onLengthChange: { viewModel.updateLength($0) }
                    )
                }
                .padding()
                .padding(.bottom, 20)
            }

            // ── Progress saved toast ───────────────────────────────────────
            // Floats above the scroll content for 1.5s then fades away.
            // Reassures the user their chapter was saved to cloud.
            if showSavedToast {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.secondary)
                    Text("Progress saved")
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(Theme.CornerRadius.lg)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .navigationTitle(viewModel.book.title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.saveOnExit()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showSavedToast)
    }

    private func showSaveToast() {
        showSavedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSavedToast = false
        }
    }
}

// MARK: - Compact Book Header

struct CompactBookHeader: View {
    let book: Book

    var body: some View {
        HStack(spacing: 16) {
            if let coverURL = book.coverImageURL {
                CachedCoverImage(bookId: book.id, coverURL: coverURL)
                    .frame(width: 80, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            } else {
                BookCoverPlaceholder(title: book.title)
                    .frame(width: 80, height: 120)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(book.title)
                    .font(.title3.bold())
                    .lineLimit(2)

                Text("by \(book.author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Series context line — shown when book is part of a series.
                // Sets expectation before generating summary: user knows
                // the AI has cross-book context available.
                if let seriesName = book.seriesName,
                   let position = book.seriesPosition {
                    HStack(spacing: 4) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 9, weight: .semibold))
                        Text("Book \(position) of \(seriesName)")
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Theme.Colors.primary.opacity(0.09))
                    .cornerRadius(Theme.CornerRadius.xs)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "book.pages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(book.totalChapters) chapters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(Theme.CornerRadius.xl)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Compact Chapter Selector

struct CompactChapterSelector: View {
    @Binding var selectedChapter: Int
    let totalChapters: Int
    let onChapterChange: (Int) -> Void

    var progressPercentage: Double {
        Double(selectedChapter) / Double(totalChapters)
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Label("Current Chapter", systemImage: "bookmark.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)

                Spacer()

                Text("Chapter \(selectedChapter) of \(totalChapters)")
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.Colors.primary)
            }

            HStack(spacing: 16) {
                Button {
                    if selectedChapter > 1 {
                        selectedChapter -= 1
                        onChapterChange(selectedChapter)
                        HapticManager.lightImpact()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(selectedChapter > 1
                                         ? Theme.Colors.primary
                                         : .gray.opacity(0.3))
                }
                .disabled(selectedChapter <= 1)

                VStack(spacing: 8) {
                    Text("\(selectedChapter)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.brandGradient)
                        .frame(minWidth: 60)

                    Slider(
                        value: Binding(
                            get: { Double(selectedChapter) },
                            set: {
                                selectedChapter = Int($0)
                                onChapterChange(selectedChapter)
                            }
                        ),
                        in: 1...Double(totalChapters),
                        step: 1
                    )
                    .tint(Theme.Colors.primary)
                }
                .frame(maxWidth: .infinity)

                Button {
                    if selectedChapter < totalChapters {
                        selectedChapter += 1
                        onChapterChange(selectedChapter)
                        HapticManager.lightImpact()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(selectedChapter < totalChapters
                                         ? Theme.Colors.primary
                                         : .gray.opacity(0.3))
                }
                .disabled(selectedChapter >= totalChapters)
            }

            ProgressBar(progress: progressPercentage, height: 6)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(Theme.CornerRadius.xl)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Action Button Pair

struct ActionButtonPair: View {
    let book: Book
    let chapter: Int
    let language: Language
    let length: SummaryLength
    let makeSummaryViewModel: (Book, Language, SummaryLength) -> SummaryViewModel
    let makeCharactersViewModel: (Book, Language) -> CharactersViewModel
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            NavigationLink {
                SummaryView(
                    viewModel: makeSummaryViewModel(book, language, length),
                    chapter: chapter,
                    bookTitle: book.title,
                    author: book.author,
                    book: book,
                    language: language
                )
                .id(chapter)
                .onAppear { onAction() }
            } label: {
                ActionCard(
                    icon: "sparkles",
                    title: "Generate Summary",
                    subtitle: "Ch \(chapter) · \(length.displayName)",
                    style: .summary
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(A11y.BookDetails.generateButton)
            .accessibilityHint(A11y.BookDetails.generateHint)

            NavigationLink {
                CharacterCardsGridView(
                    book: book,
                    chapter: chapter,
                    language: language.rawValue,
                    allBooks: []
                )
                .onAppear { onAction() }
            } label: {
                ActionCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Chat with Characters",
                    subtitle: "Spoiler-safe",
                    style: .chat
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(A11y.BookDetails.chatButton)
            .accessibilityHint(A11y.BookDetails.chatHint)
        }
    }
}

// MARK: - Action Card
//
// Both cards are solid fills at equal visual weight.
// Distinguished by gradient direction, not fill vs outline:
//   .summary — horizontal gradient (leading → trailing)
//   .chat    — diagonal gradient  (bottomLeading → topTrailing)
// Same shadow, same height, same white text. True equals.

private struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let style: CardStyle

    enum CardStyle { case summary, chat }

    private let summaryGradient = LinearGradient(
        colors: [Theme.Colors.gradientStart, Theme.Colors.gradientEnd],
        startPoint: .leading,
        endPoint: .trailing
    )

    private let chatGradient = LinearGradient(
        colors: [Theme.Colors.gradientEnd, Theme.Colors.gradientStart],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.80))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 110)
        .background(style == .summary ? summaryGradient : chatGradient)
        .cornerRadius(Theme.CornerRadius.xl)
        .shadow(color: Theme.Colors.brandShadow, radius: 10, x: 0, y: 5)
    }
}

// MARK: - Settings Section (Collapsible)

struct SettingsSection: View {
    @Binding var selectedLanguage: Language
    @Binding var selectedLength: SummaryLength
    let onLanguageChange: (Language) -> Void
    let onLengthChange: (SummaryLength) -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.secondary)

                    Text("Summary Options")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "globe").font(.caption)
                            Text(selectedLanguage.displayName).font(.caption)
                        }
                        .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: "text.alignleft").font(.caption)
                            Text(selectedLength.displayName).font(.caption)
                        }
                        .foregroundColor(.secondary)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(Theme.CornerRadius.lg)
            }

            if isExpanded {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Summary Language", systemImage: "globe")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)

                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(Language.allCases) { Text($0.displayName).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedLanguage) { _, v in onLanguageChange(v) }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Summary Length", systemImage: "text.alignleft")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)

                        Picker("Length", selection: $selectedLength) {
                            ForEach(SummaryLength.allCases) { Text($0.displayName).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedLength) { _, v in onLengthChange(v) }

                        HStack(spacing: 6) {
                            Image(systemName: lengthIcon).font(.caption).foregroundColor(.secondary)
                            Text(lengthDescription).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(Theme.CornerRadius.lg)
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    var lengthIcon: String {
        switch selectedLength {
        case .short:  return "gauge.low"
        case .medium: return "gauge.medium"
        }
    }

    var lengthDescription: String {
        switch selectedLength {
        case .short:  return "Quick recap — perfect for a refresh"
        case .medium: return "Comprehensive summary — nothing missed"
        }
    }
}
