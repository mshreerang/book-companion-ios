import SwiftUI

struct ProgressInputView: View {

    @StateObject private var viewModel: ProgressInputViewModel
    private let makeSummaryViewModel: (Book, Language, SummaryLength) -> SummaryViewModel
    private let makeCharactersViewModel: (Book, Language) -> CharactersViewModel

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
        ScrollView {
            VStack(spacing: 20) {
                // Compact Header with Book Cover
                CompactBookHeader(book: viewModel.book)
                
                // Compact Chapter Selector (Horizontal)
                CompactChapterSelector(
                    selectedChapter: $viewModel.selectedChapter,
                    totalChapters: viewModel.book.totalChapters,
                    onChapterChange: { viewModel.updateChapter($0) }
                )
                
                // PRIMARY ACTION - Always visible, no scroll needed
                PrimaryActionButton(
                    book: viewModel.book,
                    chapter: viewModel.selectedChapter,
                    language: viewModel.selectedLanguage,
                    length: viewModel.selectedLength,
                    makeSummaryViewModel: makeSummaryViewModel
                )
                
                // Secondary Action
                SecondaryActionButton(
                    book: viewModel.book,
                    chapter: viewModel.selectedChapter,
                    language: viewModel.selectedLanguage,
                    length: viewModel.selectedLength,
                    makeCharactersViewModel: makeCharactersViewModel
                )
                
                // Settings (Collapsible)
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
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.saveOnExit()
        }
    }
}

// MARK: - Compact Book Header

struct CompactBookHeader: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 16) {
            // Book Cover (smaller)
            if let coverURL = book.coverImageURL {
                CachedCoverImage(bookId: book.id, coverURL: coverURL)
                    .frame(width: 80, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            } else {
                BookCoverPlaceholder(title: book.title)
                    .frame(width: 80, height: 120)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            }
            
            // Book Info
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.title3.bold())
                    .lineLimit(2)
                
                Text("by \(book.author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                // Progress indicator
                HStack(spacing: 8) {
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
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Compact Chapter Selector (Horizontal)

struct CompactChapterSelector: View {
    @Binding var selectedChapter: Int
    let totalChapters: Int
    let onChapterChange: (Int) -> Void
    
    var progressPercentage: Double {
        Double(selectedChapter) / Double(totalChapters)
    }
    
    var body: some View {
        VStack(spacing: 14) {
            // Header with chapter info
            HStack {
                Label("Current Chapter", systemImage: "bookmark.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Chapter \(selectedChapter) of \(totalChapters)")
                    .font(.subheadline.bold())
                    .foregroundColor(.blue)
            }
            
            // Horizontal selector
            HStack(spacing: 16) {
                // Decrease Button
                Button(action: {
                    if selectedChapter > 1 {
                        selectedChapter -= 1
                        onChapterChange(selectedChapter)
                        HapticManager.lightImpact()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(selectedChapter > 1 ? .blue : .gray.opacity(0.3))
                }
                .disabled(selectedChapter <= 1)
                
                // Chapter Display + Slider
                VStack(spacing: 8) {
                    // Chapter number (medium size)
                    Text("\(selectedChapter)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(minWidth: 60)
                    
                    // Slider
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
                    .tint(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                .frame(maxWidth: .infinity)
                
                // Increase Button
                Button(action: {
                    if selectedChapter < totalChapters {
                        selectedChapter += 1
                        onChapterChange(selectedChapter)
                        HapticManager.lightImpact()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(selectedChapter < totalChapters ? .blue : .gray.opacity(0.3))
                }
                .disabled(selectedChapter >= totalChapters)
            }
            
            // Progress bar
            ProgressBar(progress: progressPercentage, height: 6)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Primary Action Button

struct PrimaryActionButton: View {
    let book: Book
    let chapter: Int
    let language: Language
    let length: SummaryLength
    let makeSummaryViewModel: (Book, Language, SummaryLength) -> SummaryViewModel
    
    var body: some View {
        NavigationLink {
            SummaryView(
                viewModel: makeSummaryViewModel(book, language, length),
                chapter: chapter
            )
            .id(chapter)
        } label: {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Generate Summary")
                        .font(.headline)
                    Text("Chapter \(chapter) • \(length.displayName)")
                        .font(.caption)
                        .opacity(0.9)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body.bold())
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .accessibilityLabel(A11y.BookDetails.generateButton)
        .accessibilityHint(A11y.BookDetails.generateHint)
    }
}

// MARK: - Secondary Action Button

struct SecondaryActionButton: View {
    let book: Book
    let chapter: Int
    let language: Language
    let length: SummaryLength
    let makeCharactersViewModel: (Book, Language) -> CharactersViewModel
    
    var body: some View {
        NavigationLink {
            CharactersLoadingView(
                viewModel: makeCharactersViewModel(book, language),
                chapter: chapter,
                length: length
            )
        } label: {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.title3)
                
                Text("View Characters")
                    .font(.subheadline.bold())
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
            }
            .foregroundColor(.primary)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
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
            // Header (always visible)
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.secondary)
                    
                    Text("Settings")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Current settings preview
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.caption)
                            Text(selectedLanguage.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "text.alignleft")
                                .font(.caption)
                            Text(selectedLength.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Expandable content
            if isExpanded {
                VStack(spacing: 16) {
                    // Language picker
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Summary Language", systemImage: "globe")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(Language.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedLanguage) { _, newValue in
                            onLanguageChange(newValue)
                        }
                    }
                    
                    Divider()
                    
                    // Length picker
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Summary Length", systemImage: "text.alignleft")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        Picker("Length", selection: $selectedLength) {
                            ForEach(SummaryLength.allCases) { length in
                                Text(length.displayName).tag(length)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedLength) { _, newValue in
                            onLengthChange(newValue)
                        }
                        
                        // Description
                        HStack(spacing: 6) {
                            Image(systemName: lengthIcon)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(lengthDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    var lengthIcon: String {
        switch selectedLength {
        case .short: return "gauge.low"
        case .medium: return "gauge.medium"
        }
    }
    
    var lengthDescription: String {
        switch selectedLength {
        case .short: return "Quick recap - perfect for a refresh"
        case .medium: return "Comprehensive summary - nothing missed"
        }
    }
}
