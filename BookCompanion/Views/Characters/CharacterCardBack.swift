import SwiftUI

struct CharacterCardBack: View {
    let character: CharacterCard?
    let isLoading: Bool
    let book: Book
    let chapter: Int
    @Binding var showChat: Bool

    var body: some View {
        ZStack {
            Color(.systemGray6)

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView().scaleEffect(1.2)
                    Text("Analysing character...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let character = character {
                loadedContent(character)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .cornerRadius(20)
    }

    // MARK: - Loaded content

    // Key layout: VStack with ScrollView on top and the Chat button
    // PINNED at the bottom — it never scrolls out of view no matter how
    // long the character summary is.
    private func loadedContent(_ character: CharacterCard) -> some View {
        VStack(spacing: 0) {

            // ── Scrollable details ────────────────────────────────────────
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(character.fullName)
                            .font(.title3.bold())
                            .foregroundColor(.primary)

                        if let role = character.role, !role.isEmpty {
                            Text(role)
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                        }
                    }

                    Divider()

                    if let evolution = character.currentSituation, !evolution.isEmpty {
                        InfoSection(
                            title: "Development So Far",
                            icon: "arrow.up.forward.circle.fill",
                            color: .purple,
                            content: evolution
                        )
                    }

                    if let description = character.description, !description.isEmpty {
                        InfoSection(
                            title: "About",
                            icon: "person.fill",
                            color: .blue,
                            content: description
                        )
                    }

                    if let relationships = character.relationships, !relationships.isEmpty {
                        InfoSection(
                            title: "Relationships",
                            icon: "person.2.fill",
                            color: .green,
                            content: relationships
                        )
                    }

                    // Bottom breathing room so the last section
                    // isn't flush against the button divider
                    Spacer(minLength: 12)
                }
                .padding(16)
            }

            // ── Pinned footer — ALWAYS VISIBLE ────────────────────────────
            // Sits outside the ScrollView so it can never be scrolled away.
            if FeatureFlags.characterChat {
                chatButton(character)
            }
        }
    }

    // MARK: - Chat button

    private func chatButton(_ character: CharacterCard) -> some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                showChat = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Chat with \(character.fullName)")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.85), Color.purple.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(0) // card corners clip this at the bottom
            }
        }
        // Clip to the card's bottom corners only
        .clipShape(
            RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight])
        )
    }
}

// MARK: - InfoSection

struct InfoSection: View {
    let title: String
    let icon: String
    let color: Color
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption.bold())
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .tracking(0.5)
            }
            Text(content)
                .font(.subheadline)
                .lineSpacing(3)
                .foregroundColor(.primary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - RoundedCorner shape (used by chat button footer)

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    CharacterCardBack(
        character: CharacterCard(
            id: "1",
            fullName: "Hermione Granger",
            description: "The brightest witch of her age, fiercely loyal and principled. She holds herself and others to the highest standards and is not afraid to speak up, even when it makes her unpopular.",
            relationships: "Best friends with Harry Potter and Ron Weasley. Has a complicated rivalry with Draco Malfoy. Deeply respected by Dumbledore.",
            currentSituation: "Currently in her fourth year and visibly distressed by the Triwizard Tournament. She alone believes Harry did not put his own name in the Goblet of Fire and is working tirelessly to help him prepare for the tasks.",
            role: "Deuteragonist"
        ),
        isLoading: false,
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
        showChat: .constant(false)
    )
    .frame(width: 340, height: 520)
    .padding()
}
