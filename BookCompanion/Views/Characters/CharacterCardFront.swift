import SwiftUI

struct CharacterCardFront: View {
    let name: String

    var body: some View {
        ZStack {
            // Background — brand gradient diagonal for consistency
            Theme.Colors.brandGradientDiagonal
                .opacity(0.85)

            VStack(spacing: 14) {
                Spacer()

                // CharacterAvatar gives each card a unique colour-coded
                // initials circle — replaces the generic 👤 emoji.
                // The avatar uses a stable hash so colours are consistent
                // across app launches.
                CharacterAvatar(name: name, size: 64)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                Text(name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 12)

                Spacer()

                // Subtle tap affordance — icon only, no text label
                Image(systemName: "chevron.up.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 12)
            }
            .padding()
        }
        .cornerRadius(Theme.CornerRadius.xl)
        .shadow(color: Theme.Colors.brandShadow, radius: 3, x: 0, y: 2)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        CharacterCardFront(name: "Harry Potter")
        CharacterCardFront(name: "Hermione Granger")
        CharacterCardFront(name: "Ron Weasley")
        CharacterCardFront(name: "Albus Dumbledore")
    }
    .padding()
}
