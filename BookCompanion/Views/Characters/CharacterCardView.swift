import SwiftUI

// CharacterCardView is now the EXPANDED card only.
// It lives in the overlay layer of CharacterCardsGridView.
// The grid thumbnail is just CharacterCardFront — no matchedGeometryEffect.

struct CharacterCardView: View {
    let name: String
    let book: Book
    let chapter: Int
    @ObservedObject var viewModel: CharacterCardsViewModel
    var onDismiss: () -> Void

    @EnvironmentObject private var store: StoreManager
    @State private var isFlipped = false
    @State private var character: CharacterCard?
    @State private var isLoadingDetails = false
    @State private var showChat = false
    @State private var showPaywall = false
    @State private var isQuotaExceeded = false

    var body: some View {
        ZStack {
            // Back face — shown when flipped
            if isFlipped {
                CharacterCardBack(
                    character: character,
                    isLoading: isLoadingDetails,
                    book: book,
                    chapter: chapter,
                    showChat: $showChat
                )
                .rotation3DEffect(.degrees(0), axis: (x: 0, y: 1, z: 0))
                // Back face starts at 180° in the unflipped state
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 1 : 0)
            }

            // Front face — hidden when flipped
            if !isFlipped {
                CharacterCardFront(name: name)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .opacity(isFlipped ? 0 : 1)
            }

            // Close button — always on top
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, Color.black.opacity(0.3))
                            .padding(12)
                    }
                }
                Spacer()
            }
        }
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 24, x: 0, y: 12)
        .overlay {
            if isQuotaExceeded {
                ZStack {
                    Color(.systemGray6).cornerRadius(20)
                    VStack(spacing: 16) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                        Text("Monthly Limit Reached")
                            .font(.headline)
                        Text("You've used all 5 free character analyses this month. Upgrade to Pro for unlimited.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Upgrade to Pro") {
                            showPaywall = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    VStack {
                        HStack {
                            Spacer()
                            Button { onDismiss() } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white, Color.black.opacity(0.3))
                                    .padding(12)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(triggerReason: "Upgrade to Pro for unlimited character analyses.")
                .environmentObject(StoreManager.shared)
        }
        // When Pro is granted (purchase or restore), dismiss the paywall sheet
        // and clear the quota exceeded state so characters reload automatically
        .onChange(of: store.isPro) { _, isPro in
            if isPro {
                showPaywall = false
                isQuotaExceeded = false
            }
        }
        .onAppear {
            // Brief pause so the zoom animation completes before the flip starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                    isFlipped = true
                }
                loadDetailsIfNeeded()
            }
        }
        .sheet(isPresented: $showChat) {
            if FeatureFlags.characterChat, let character = character {
                CharacterChatView(
                    character: character,
                    book: book,
                    chapter: chapter,
                    language: book.language
                )
            }
        }
    }

    private func loadDetailsIfNeeded() {
        if let cached = viewModel.detailsCache[name] {
            character = cached
            return
        }
        isLoadingDetails = true
        Task {
            let (result, quotaError) = await viewModel.loadDetails(for: name)
            await MainActor.run {
                character = result
                isQuotaExceeded = quotaError
                isLoadingDetails = false
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.4).ignoresSafeArea()
        CharacterCardView(
            name: "Hermione Granger",
            book: Book(
                id: UUID(),
                title: "Harry Potter and the Goblet of Fire",
                author: "J.K. Rowling",
                language: .english,
                totalChapters: 37,
                coverImageURL: nil,
                createdAt: Date()
            ),
            chapter: 33,
            viewModel: CharacterCardsViewModel(
                book: Book(
                    id: UUID(),
                    title: "Harry Potter and the Goblet of Fire",
                    author: "J.K. Rowling",
                    language: .english,
                    totalChapters: 37,
                    createdAt: Date()
                ),
                chapter: 33
            ),
            onDismiss: {}
        )
        .environmentObject(StoreManager.shared)
        .padding(20)
    }
}
