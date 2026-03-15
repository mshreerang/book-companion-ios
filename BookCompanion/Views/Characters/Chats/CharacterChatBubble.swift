//
//  CharacterChatBubble.swift
//  BookCompanion
//
//  Created by Shree on 27/02/2026.
//

import SwiftUI

struct CharacterChatBubble: View {
    let message: CharacterChatMessage
    let characterName: String
    var onUpgrade: (() -> Void)? = nil   // called when user taps upgrade in quotaCard

    var body: some View {
        switch message.role {
        case .user:      userBubble
        case .character: characterBubble
        case .system:    systemCard
        }
    }

    // MARK: - User Bubble
    // Right-aligned, brand gradient, leaves only a small left indent

    private var userBubble: some View {
        HStack {
            Spacer(minLength: 48)   // just enough to distinguish from character bubbles
            Text(message.content)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Theme.Colors.brandGradient)
                .cornerRadius(Theme.CornerRadius.lg)
                .cornerRadius(4, corners: .topRight)
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Character Bubble
    // Left-aligned, avatar, uses almost full width, renders *action* text differently

    private var characterBubble: some View {
        HStack(alignment: .bottom, spacing: Theme.Spacing.xs) {

            // Avatar
            Circle()
                .fill(Theme.Colors.brandGradient)
                .frame(width: 30, height: 30)
                .overlay(
                    Text(String(characterName.prefix(1)).uppercased())
                        .font(.caption.bold())
                        .foregroundColor(.white)
                )
                .alignmentGuide(.bottom) { d in d[.bottom] }

            // Bubble content
            VStack(alignment: .leading, spacing: 0) {
                if message.content.isEmpty && message.isStreaming {
                    TypingIndicator()
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Color(.systemGray6))
                        .cornerRadius(Theme.CornerRadius.lg)
                        .cornerRadius(4, corners: .bottomLeft)
                } else {
                    // Parse content into runs of dialogue and *action* text
                    parsedContent
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Color(.systemGray6))
                        .cornerRadius(Theme.CornerRadius.lg)
                        .cornerRadius(4, corners: .bottomLeft)
                        // Streaming cursor sits outside the text so it doesn't reflow
                        .overlay(alignment: .bottomTrailing) {
                            if message.isStreaming {
                                Text("▌")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.primary)
                                    .padding([.bottom, .trailing], 6)
                            }
                        }
                }
            }
            // No trailing Spacer — bubble grows to fill available width naturally
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - *Action* text parser
    // Splits "Hello! *looks up from book* Are you alright?" into
    // dialogue runs (normal) and action runs (italic, dimmed).

    private var parsedContent: some View {
        let segments = parseSegments(message.content)
        // Build an AttributedString so everything stays in one Text — no wrapping issues
        var attributed = AttributedString()

        for segment in segments {
            var part = AttributedString(segment.text)
            if segment.isAction {
                part.font = .subheadline.italic()
                part.foregroundColor = .secondary
            } else {
                part.font = .subheadline
                part.foregroundColor = UIColor.label.swiftUIColor
            }
            attributed.append(part)
        }

        return Text(attributed)
            .fixedSize(horizontal: false, vertical: true)
    }

    // Splits on *...* patterns
    private func parseSegments(_ text: String) -> [(text: String, isAction: Bool)] {
        var segments: [(String, Bool)] = []
        var remaining = text
        var isAction = false

        // Walk through splitting on `*`
        while let starRange = remaining.range(of: "*") {
            let before = String(remaining[remaining.startIndex..<starRange.lowerBound])
            if !before.isEmpty {
                segments.append((before, isAction))
            }
            remaining = String(remaining[starRange.upperBound...])
            isAction.toggle()
        }
        if !remaining.isEmpty {
            segments.append((remaining, isAction))
        }
        return segments
    }

    // MARK: - System Cards

    @ViewBuilder
    private var systemCard: some View {
        switch message.systemKind {
        case .safetyBlock, .safetyEnd:
            safetyCard(icon: "shield.fill", color: Color.red.opacity(0.8))
        case .quotaLimit:
            quotaCard
        case .none:
            EmptyView()
        }
    }

    private func safetyCard(icon: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            Text(message.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.07))
        .cornerRadius(Theme.CornerRadius.md)
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var quotaCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "star.fill")
                    .foregroundColor(Theme.Colors.warning)
                    .font(.caption)
                Text("Pro Feature")
                    .font(.caption.bold())
                    .foregroundColor(Theme.Colors.warning)
            }
            Text(message.content)
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Upgrade to Pro →") {
                onUpgrade?()
            }
            .font(.caption.bold())
            .foregroundColor(Theme.Colors.primary)
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(Theme.CornerRadius.md)
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - UIColor extension for AttributedString compatibility

private extension UIColor {
    var swiftUIColor: Color { Color(self) }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .scaleEffect(phase == i ? 1.3 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.4)
                            .repeatForever()
                            .delay(Double(i) * 0.15),
                        value: phase
                    )
            }
        }
        .onAppear { phase = 1 }
    }
}

// MARK: - Corner Radius Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

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
