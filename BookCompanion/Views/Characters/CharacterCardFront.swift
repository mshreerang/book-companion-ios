import SwiftUI

struct CharacterCardFront: View {
    let name: String

    var body: some View {
        ZStack {
            Theme.Colors.brandGradientDiagonal
                .opacity(0.85)

            VStack(spacing: 8) {
                Spacer(minLength: 4)

                CharacterAvatar(name: name, size: 60)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)

                Spacer(minLength: 4)

                Image(systemName: "chevron.up.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cornerRadius(Theme.CornerRadius.xl)
        .clipped()
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
