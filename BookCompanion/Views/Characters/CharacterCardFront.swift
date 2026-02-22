import SwiftUI

struct CharacterCardFront: View {
    let name: String
    @Namespace private var namespace
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 12) {
                Spacer()
                
                // Character emoji/avatar placeholder
                Text("👤")
                    .font(.system(size: 50))
                
                // Character name
                Text(name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .matchedGeometryEffect(id: "name-\(name)", in: namespace)
                
                Spacer()
                
                // Tap hint
                Text("Tap to view details")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 8)
            }
            .padding()
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    CharacterCardFront(name: "Harry Potter")
        .frame(width: 150, height: 200)
        .padding()
}
