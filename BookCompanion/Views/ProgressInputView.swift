import SwiftUI

struct ProgressInputView: View {

    @StateObject private var viewModel: ProgressInputViewModel
    private let makeSummaryViewModel: (Book, Language, SummaryLength) -> SummaryViewModel
    private let makeCharactersViewModel: (Book, Language) -> CharactersViewModel
    
    // Shared across Characters + Chat tabs — one API call, one cache
    @StateObject private var characterVM: CharacterCardsViewModel
    private let settingsManager: SettingsManager

    @State private var showSavedToast = false
    @State private var selectedTab: Int = 0

    init(
            viewModel: ProgressInputViewModel,
            settingsManager: SettingsManager,
            makeSummaryViewModel: @escaping (Book, Language, SummaryLength) -> SummaryViewModel,
            makeCharactersViewModel: @escaping (Book, Language) -> CharactersViewModel
        ) {
            let pvm = viewModel
            _viewModel = StateObject(wrappedValue: pvm)
            self.settingsManager = settingsManager
            self.makeSummaryViewModel = makeSummaryViewModel
            self.makeCharactersViewModel = makeCharactersViewModel
        _characterVM = StateObject(wrappedValue: CharacterCardsViewModel(
            book: pvm.book,
            chapter: pvm.selectedChapter,
            language: pvm.selectedLanguage.displayName
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {

                // ── Fixed header ──────────────────────────────────────────
                VStack(spacing: 8) {
                    CompactBookHeader(
                        book: viewModel.book,
                        currentChapter: viewModel.selectedChapter
                    )
                    .padding(.horizontal)
                    .padding(.top, 10)

                    CompactChapterSelector(
                        selectedChapter: $viewModel.selectedChapter,
                        totalChapters: viewModel.book.totalChapters,
                        onChapterChange: { viewModel.updateChapter($0) }
                    )
                    .padding(.horizontal)
                }
                .background(Color(.systemGroupedBackground))

                // ── Book-style tab shelf ──────────────────────────────────
                HStack(spacing: 4) {
                    bookTab(title: "Summary",    index: 0, spineColor: Theme.Colors.primary)
                    bookTab(title: "Characters", index: 1, spineColor: Theme.Colors.secondary)
                    bookTab(title: "Chat",       index: 2, spineColor: Color(red: 0.29, green: 0.38, blue: 0.31))
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .background(Color(.systemGroupedBackground))

                // ── Tab content ───────────────────────────────────────────
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case 0: summaryTab
                        case 1: charactersTab
                        case 2: chatTab
                        default: summaryTab
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
                .background(
                    // Content area matches the active tab — white card feel
                    VStack(spacing: 0) {
                        Color(.systemBackground)
                        Spacer()
                    }
                )
            }

            // ── Progress saved toast ──────────────────────────────────────
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    SettingsView(settingsManager: settingsManager)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .onDisappear { viewModel.saveOnExit() }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showSavedToast)
    }

    // MARK: - Book-Style Tab

    private func bookTab(title: String, index: Int, spineColor: Color) -> some View {
        let isActive = selectedTab == index
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index }
            HapticManager.lightImpact()
        } label: {
            ZStack(alignment: .leading) {
                // Tab body
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(isActive ? Color(.systemBackground) : Color(.systemGray5).opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .stroke(isActive ? Color(.separator).opacity(0.4) : Color.clear, lineWidth: 0.5)
                    )

                // Spine
                HStack(spacing: 0) {
                    spineColor
                        .frame(width: 4)
                        .cornerRadius(Theme.CornerRadius.xs)
                    Spacer()
                }

                // Label
                Text(title)
                    .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                    .foregroundColor(isActive ? Theme.Colors.primary : Color(.systemGray2))
                    .frame(maxWidth: .infinity)
                    .padding(.leading, 4)
            }
            .frame(height: isActive ? 44 : 38)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        // Active tab sits higher — book tab effect
        .offset(y: isActive ? 0 : 4)
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }

    // MARK: - Summary Tab

    private var summaryTab: some View {
        VStack(spacing: 16) {
            NavigationLink {
                SummaryView(
                    viewModel: makeSummaryViewModel(
                        viewModel.book,
                        viewModel.selectedLanguage,
                        viewModel.selectedLength
                    ),
                    chapter: viewModel.selectedChapter,
                    bookTitle: viewModel.book.title,
                    author: viewModel.book.author,
                    book: viewModel.book,
                    language: viewModel.selectedLanguage
                )
                .id(viewModel.selectedChapter)
                .onAppear {
                    viewModel.syncChapterToCloud()
                    showSaveToast()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Generate Summary")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Text("Ch \(viewModel.selectedChapter) · \(viewModel.selectedLength.displayName)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.8))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Theme.Colors.brandGradient)
                .cornerRadius(Theme.CornerRadius.xl)
                .shadow(color: Theme.Colors.brandShadow, radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(A11y.BookDetails.generateButton)
            .accessibilityHint(A11y.BookDetails.generateHint)

            SettingsSection(
                selectedLanguage: $viewModel.selectedLanguage,
                selectedLength: $viewModel.selectedLength,
                onLanguageChange: { viewModel.updateLanguage($0) },
                onLengthChange: { viewModel.updateLength($0) }
            )
        }
    }

    // MARK: - Characters Tab

    private var charactersTab: some View {
        CharacterAnalysisListView(
            book: viewModel.book,
            chapter: viewModel.selectedChapter,
            language: viewModel.selectedLanguage,
            viewModel: characterVM
        )
        .environmentObject(StoreManager.shared)
        .onAppear {
            viewModel.syncChapterToCloud()
            showSaveToast()
            if characterVM.names.isEmpty && !characterVM.isLoadingNames {
                Task { await characterVM.loadNames() }
            }
        }
    }

    // MARK: - Chat Tab

    private var chatTab: some View {
        CharacterSelectView(
            book: viewModel.book,
            chapter: viewModel.selectedChapter,
            language: viewModel.selectedLanguage,
            characterVM: characterVM
        )
        .onAppear {
            viewModel.syncChapterToCloud()
            showSaveToast()
            if characterVM.names.isEmpty && !characterVM.isLoadingNames {
                Task { await characterVM.loadNames() }
            }
        }
    }

    // MARK: - Helpers

    private func showSaveToast() {
        showSavedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSavedToast = false
        }
    }
}

// MARK: - Character Analysis List View

private struct CharacterAnalysisListView: View {
    let book: Book
    let chapter: Int
    let language: Language
    @ObservedObject var viewModel: CharacterCardsViewModel
    @EnvironmentObject private var store: StoreManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safe up to Chapter \(chapter)")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.Colors.secondary.opacity(0.12))
                .foregroundColor(Theme.Colors.secondary)
                .cornerRadius(Theme.CornerRadius.sm)

            if viewModel.isLoadingNames {
                HStack(spacing: 10) {
                    ProgressView().scaleEffect(0.8)
                    Text("Finding characters…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else if let limited = viewModel.limitedMessage {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Characters unavailable").font(.subheadline.bold())
                    Text(limited).font(.caption).foregroundColor(.secondary)
                }
            } else if viewModel.names.isEmpty {
                Text("No characters found yet. Try reading more chapters.")
                    .font(.subheadline).foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.names, id: \.self) { name in
                        CharacterAnalysisRow(
                            name: name,
                            book: book,
                            chapter: chapter,
                            language: language,
                            viewModel: viewModel
                        )
                        .environmentObject(store)
                    }
                }
            }
        }
    }
}

// MARK: - Character Analysis Row

private struct CharacterAnalysisRow: View {
    let name: String
    let book: Book
    let chapter: Int
    let language: Language
    @ObservedObject var viewModel: CharacterCardsViewModel
    @EnvironmentObject private var store: StoreManager
    @State private var showCard = false

    private static let avatarColors: [Color] = [
        Theme.Colors.primary, Theme.Colors.secondary,
        Color(red: 0.29, green: 0.38, blue: 0.31), Color(red: 0.48, green: 0.36, blue: 0.23),
        Color(red: 0.23, green: 0.37, blue: 0.31), Color(red: 0.42, green: 0.31, blue: 0.23),
    ]
    private var avatarColor: Color { Self.avatarColors[abs(name.hashValue) % Self.avatarColors.count] }
    private var initials: String {
        let p = name.split(separator: " ")
        return p.count >= 2 ? String(p[0].prefix(1)) + String(p[1].prefix(1)) : String(name.prefix(2))
    }

    var body: some View {
        Button { showCard = true } label: {
            HStack(spacing: 12) {
                Circle().fill(avatarColor).frame(width: 40, height: 40)
                    .overlay(Text(initials.uppercased()).font(.system(size: 14, weight: .semibold)).foregroundColor(.white))
                Text(name).font(.subheadline.weight(.medium)).foregroundColor(.primary)
                Spacer()
                Image(systemName: "info.circle").font(.caption.bold()).foregroundColor(.secondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(Theme.CornerRadius.lg)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showCard) {
            ZStack {
                Color.black.opacity(0.4).ignoresSafeArea()
                CharacterCardView(name: name, book: book, chapter: chapter, viewModel: viewModel, onDismiss: { showCard = false })
                    .padding(.horizontal, 20).padding(.vertical, 60)
            }
            .environmentObject(store)
        }
    }
}

// MARK: - Credit Counter Bar

private struct CreditCounterBar: View {
    @EnvironmentObject private var storeManager: StoreManager
    @StateObject private var usageManager = UsageManager.shared
    @State private var showPaywall = false

    private var totalSummaries: Int { usageManager.summariesRemaining + storeManager.topupSummaryCredits }
    private var totalCharacters: Int { storeManager.topupCharacterCredits }
    private var totalChats: Int { storeManager.topupChatCredits }
    private var allZero: Bool { totalSummaries == 0 && totalCharacters == 0 && totalChats == 0 }

    var body: some View {
        if storeManager.isPro { return AnyView(EmptyView()) }
        return AnyView(
            Button { showPaywall = true } label: {
                HStack(spacing: 0) {
                    creditPill(icon: "sparkles",                          count: totalSummaries,  label: "summaries")
                    Divider().frame(height: 20).padding(.horizontal, 8)
                    creditPill(icon: "person.2.fill",                     count: totalCharacters, label: "characters")
                    Divider().frame(height: 20).padding(.horizontal, 8)
                    creditPill(icon: "bubble.left.and.bubble.right.fill", count: totalChats,      label: "chats")
                    Spacer()
                    if allZero { Text("Get more →").font(.caption.weight(.medium)).foregroundColor(Theme.Colors.secondary) }
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(.systemBackground))
                .cornerRadius(Theme.CornerRadius.lg)
                .overlay(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg).stroke(Theme.Colors.primary.opacity(0.12), lineWidth: 1))
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(storeManager) }
            .task { await storeManager.fetchTopupCredits(); usageManager.refresh() }
            .onAppear { Task { await storeManager.fetchTopupCredits(); usageManager.refresh() } }
        )
    }

    private func creditPill(icon: String, count: Int, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10, weight: .semibold))
                .foregroundColor(count > 0 ? Theme.Colors.secondary : Color(.systemGray3))
            if count > 0 {
                Text("\(count)").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.Colors.primary)
                Text(label).font(.system(size: 11)).foregroundColor(.secondary)
            } else {
                Text("0 \(label)").font(.system(size: 11)).foregroundColor(Color(.systemGray3))
            }
        }
    }
}

// MARK: - Compact Book Header

struct CompactBookHeader: View {
    let book: Book
    let currentChapter: Int

    private var progress: Double {
        guard book.totalChapters > 0 else { return 0 }
        return min(1.0, Double(currentChapter) / Double(book.totalChapters))
    }
    private var chaptersRemaining: Int { max(0, book.totalChapters - currentChapter) }

    var body: some View {
        VStack(spacing: 0) {
            // Top: cover + meta
            HStack(spacing: 12) {
                Group {
                    if let coverURL = book.coverImageURL {
                        CachedCoverImage(bookId: book.id, coverURL: coverURL)
                    } else {
                        BookCoverPlaceholder(title: book.title)
                    }
                }
                .frame(width: 64, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 3) {
                    Text(book.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2).foregroundColor(.primary)
                    Text(book.author)
                        .font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1)

                    HStack(spacing: 4) {
                        Text(book.bookType.displayName)
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.Colors.primary.opacity(0.1))
                            .foregroundColor(Theme.Colors.primary).cornerRadius(4)
                        if let seriesName = book.seriesName, let position = book.seriesPosition {
                            Text("Book \(position) · \(seriesName)")
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Theme.Colors.secondary.opacity(0.1))
                                .foregroundColor(Theme.Colors.secondary).cornerRadius(4)
                                .lineLimit(1)
                        }
                    }
                    .padding(.top, 2)

                    HStack(spacing: 8) {
                        // Progress ring
                        ZStack {
                            Circle().stroke(Color(.systemGray5), lineWidth: 4).frame(width: 36, height: 36)
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(Theme.Colors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 36, height: 36)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.4), value: progress)
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(Theme.Colors.primary)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Ch \(currentChapter) of \(book.totalChapters)")
                                .font(.system(size: 10, weight: .medium)).foregroundColor(.primary)
                            Text("\(chaptersRemaining) chapters left")
                                .font(.system(size: 9)).foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)

            // Stats strip
            Divider()
            HStack(spacing: 0) {
                statCell(value: "\(book.totalChapters)", label: "chapters")
                if let pages = book.pageCount {
                    Divider().frame(height: 28)
                    statCell(value: "\(pages)", label: "pages")
                }
                Divider().frame(height: 28)
                if let position = book.seriesPosition {
                    statCell(value: "Book \(position)", label: "in series", accent: true)
                } else {
                    statCell(value: book.bookType.displayName, label: "type")
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(Theme.CornerRadius.xl)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func statCell(value: String, label: String, accent: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 12, weight: .semibold))
                .foregroundColor(accent ? Theme.Colors.secondary : Theme.Colors.primary)
            Text(label).font(.system(size: 9)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 6)
    }
}

// MARK: - Compact Chapter Selector

struct CompactChapterSelector: View {
    @Binding var selectedChapter: Int
    let totalChapters: Int
    let onChapterChange: (Int) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Current Chapter", systemImage: "bookmark.fill")
                    .font(.caption.bold()).foregroundColor(.secondary)
                Spacer()
                Text("Chapter \(selectedChapter) of \(totalChapters)")
                    .font(.caption.bold()).foregroundColor(Theme.Colors.primary)
            }
            HStack(spacing: 12) {
                Button {
                    if selectedChapter > 1 { selectedChapter -= 1; onChapterChange(selectedChapter); HapticManager.lightImpact() }
                } label: {
                    Image(systemName: "minus.circle.fill").font(.system(size: 28))
                        .foregroundColor(selectedChapter > 1 ? Theme.Colors.primary : .gray.opacity(0.3))
                }
                .disabled(selectedChapter <= 1)

                HStack(spacing: 10) {
                    Text("\(selectedChapter)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.brandGradient).frame(minWidth: 32)
                    Slider(
                        value: Binding(get: { Double(selectedChapter) }, set: { selectedChapter = Int($0); onChapterChange(selectedChapter) }),
                        in: 1...Double(max(totalChapters, 1)), step: 1
                    )
                    .tint(Theme.Colors.primary)
                    .onChange(of: selectedChapter) { _, _ in HapticManager.lightImpact() }
                }

                Button {
                    if selectedChapter < totalChapters { selectedChapter += 1; onChapterChange(selectedChapter); HapticManager.lightImpact() }
                } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 28))
                        .foregroundColor(selectedChapter < totalChapters ? Theme.Colors.primary : .gray.opacity(0.3))
                }
                .disabled(selectedChapter >= totalChapters)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(Theme.CornerRadius.xl)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Settings Section

struct SettingsSection: View {
    @Binding var selectedLanguage: Language
    @Binding var selectedLength: SummaryLength
    let onLanguageChange: (Language) -> Void
    let onLengthChange: (SummaryLength) -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } } label: {
                HStack {
                    Image(systemName: "gearshape.fill").foregroundColor(.secondary)
                    Text("Summary Options").font(.subheadline.bold()).foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 12) {
                        HStack(spacing: 4) { Image(systemName: "globe").font(.caption); Text(selectedLanguage.displayName).font(.caption) }.foregroundColor(.secondary)
                        HStack(spacing: 4) { Image(systemName: "text.alignleft").font(.caption); Text(selectedLength.displayName).font(.caption) }.foregroundColor(.secondary)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down").font(.caption.bold()).foregroundColor(.secondary)
                    }
                }
                .padding().background(Color(.systemGray6)).cornerRadius(Theme.CornerRadius.lg)
            }
            if isExpanded {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Summary Language", systemImage: "globe").font(.caption.bold()).foregroundColor(.secondary)
                        Picker("Language", selection: $selectedLanguage) { ForEach(Language.allCases) { Text($0.displayName).tag($0) } }
                            .pickerStyle(.segmented).onChange(of: selectedLanguage) { _, v in onLanguageChange(v) }
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Summary Length", systemImage: "text.alignleft").font(.caption.bold()).foregroundColor(.secondary)
                        Picker("Length", selection: $selectedLength) { ForEach(SummaryLength.allCases) { Text($0.displayName).tag($0) } }
                            .pickerStyle(.segmented).onChange(of: selectedLength) { _, v in onLengthChange(v) }
                        HStack(spacing: 6) {
                            Image(systemName: lengthIcon).font(.caption).foregroundColor(.secondary)
                            Text(lengthDescription).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .padding().background(Color(.systemBackground)).cornerRadius(Theme.CornerRadius.lg)
                .padding(.top, 8).transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    var lengthIcon: String { selectedLength == .short ? "gauge.low" : "gauge.medium" }
    var lengthDescription: String { selectedLength == .short ? "Quick recap — perfect for a refresh" : "Comprehensive summary — nothing missed" }
}

// MARK: - Quota Warning Banner

private struct QuotaWarningBanner: View {
    @EnvironmentObject private var usageManager: UsageManager
    @EnvironmentObject private var storeManager: StoreManager
    @State private var showPaywall = false

    var body: some View {
        if usageManager.isNearLimit && !storeManager.isPro {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill").foregroundColor(Theme.Colors.secondary).font(.system(size: 16))
                VStack(alignment: .leading, spacing: 2) {
                    Text("1 summary remaining this month").font(.subheadline.weight(.semibold)).foregroundColor(.primary)
                    Text("Upgrade to Pro or get more credits.").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button("Get more") { showPaywall = true }
                    .font(.caption.weight(.semibold)).foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Theme.Colors.secondary).cornerRadius(Theme.CornerRadius.sm)
            }
            .padding(12)
            .background(Theme.Colors.secondary.opacity(0.08))
            .cornerRadius(Theme.CornerRadius.lg)
            .overlay(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg).stroke(Theme.Colors.secondary.opacity(0.25), lineWidth: 1))
            .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(storeManager) }
        }
    }
}
