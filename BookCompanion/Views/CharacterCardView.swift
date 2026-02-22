import SwiftUI

struct CharacterCardView: View {
    let name: String
    @ObservedObject var viewModel: CharacterCardsViewModel  // ✅ FIXED: Use parent's viewModel
    @State private var isFlipped = false
    @State private var character: CharacterCard?
    @State private var isLoadingDetails = false
    
    var body: some View {
        ZStack {
            // Back side (details)
            if isFlipped {
                CharacterCardBack(
                    character: character,
                    isLoading: isLoadingDetails
                )
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
            
            // Front side (name only)
            if !isFlipped {
                CharacterCardFront(name: name)
            }
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .onTapGesture {
            handleTap()
        }
    }
    
    private func handleTap() {
        // ✅ IMPROVEMENT #4: Haptic feedback for premium feel
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isFlipped.toggle()
        }
        
        // Load details when flipping to back
        if isFlipped && character == nil {
            loadDetails()
        }
    }
    
    private func loadDetails() {
        // ✅ IMPROVEMENT #3: Check cache first (viewModel handles this)
        if let cached = viewModel.detailsCache[name] {
            self.character = cached
            return
        }
        
        isLoadingDetails = true
        
        Task {
            let result = await viewModel.loadDetails(for: name)
            
            await MainActor.run {
                self.character = result
                self.isLoadingDetails = false
            }
        }
    }
}

#Preview {
    CharacterCardView(
        name: "Harry Potter",
        viewModel: CharacterCardsViewModel(
            book: Book(
                id: UUID(),
                title: "Harry Potter and the Philosopher's Stone",
                author: "J.K. Rowling"
            ),
            chapter: 11
        )
    )
    .frame(width: 160, height: 220)
    .padding()
}
