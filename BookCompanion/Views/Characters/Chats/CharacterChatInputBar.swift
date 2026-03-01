//
//  CharacterChatInputBar.swift
//  BookCompanion
//
//  Created by Shree on 27/02/2026.
//

import SwiftUI

struct CharacterChatInputBar: View {
    @Binding var text: String
    let isDisabled: Bool        // true when isAtLimit || isSafetyEnded || isStreaming
    let onSend: () -> Void

    private let characterLimit = 500

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: Theme.Spacing.xs) {
                // Text field
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text("Message \u{2014} be curious...")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.leading, 4)
                    }
                    TextField("", text: $text, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(1...5)
                        .disabled(isDisabled)
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Color(.systemGray6))
                .cornerRadius(Theme.CornerRadius.lg)

                // Send button
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            canSend
                                ? Theme.Colors.brandGradient
                                : LinearGradient(
                                    colors: [Color.secondary.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.xs)
            .padding(.bottom, Theme.Spacing.sm)

            // Character count warning (appears at 80% of limit)
            if text.count > characterLimit * 4 / 5 {
                HStack {
                    Spacer()
                    Text("\(characterLimit - text.count) left")
                        .font(.caption2)
                        .foregroundColor(text.count >= characterLimit ? Theme.Colors.error : Theme.Colors.warning)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.bottom, Theme.Spacing.xs)
                }
            }
        }
        .background(Color(.systemBackground))
        .onChange(of: text) {
            // Hard cap at character limit
            if text.count > characterLimit {
                text = String(text.prefix(characterLimit))
            }
        }
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isDisabled
    }
}
