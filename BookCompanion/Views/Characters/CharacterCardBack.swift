import SwiftUI

struct CharacterCardBack: View {
    let character: CharacterCard?
    let isLoading: Bool
    @Namespace private var namespace
    
    var body: some View {
        ZStack {
            // Background
            Color.white
            
            if isLoading {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading details...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let character = character {
                // Content with fading edge
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Full name header
                            Text(character.fullName)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .matchedGeometryEffect(id: "name-\(character.id)", in: namespace)
                            
                            Divider()
                            
                            // Description
                            if let description = character.description {
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("About", systemImage: "person.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            // Relationships
                            if let relationships = character.relationships {
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Relationships", systemImage: "person.2.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(relationships)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            // Current situation
                            if let situation = character.currentSituation {
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Current Situation", systemImage: "book.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(situation)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            Spacer(minLength: 40)
                            
                            // Tap hint
                            Text("Tap to flip back")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.bottom, 8)
                        }
                        .padding()
                    }
                    
                    // ✅ IMPROVEMENT #2: Fading edge to indicate scrollable content
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.8),
                            Color.white
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                    .allowsHitTesting(false)  // Don't block scrolling
                }
            }
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    CharacterCardBack(
        character: CharacterCard(
            id: "Hagrid",
            fullName: "Rubeus Hagrid",
            description: "The Keeper of Keys and Grounds at Hogwarts, a half-giant with a kind heart.",
            relationships: "Loyal friend to Harry Potter and trusted by Dumbledore.",
            currentSituation: "Helping to protect the Philosopher's Stone with Fluffy."
        ),
        isLoading: false
    )
    .frame(width: 300, height: 400)
    .padding()
}
