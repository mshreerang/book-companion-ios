//
//  CharacterChatView.swift
//  BookCompanion
//
//  Created by Shree on 27/02/2026.
//

import SwiftUI

// MARK: - CharacterChatView

struct CharacterChatView: View {
    let character: CharacterCard
    let book: Book
    let chapter: Int
    let language: Language

    @StateObject private var viewModel: CharacterChatViewModel
    @Environment(\.dismiss) private var dismiss

    // Disclaimer gate — shown on first ever chat open, blocks interaction until accepted
    @AppStorage("hasSeenChatDisclaimer") private var hasSeenChatDisclaimer = false
    @State private var showDisclaimer = false

    // Report sheet
    @State private var showReport = false

    // Scroll proxy target — scroll to bottom after each new message
    @Namespace private var bottomID

    init(character: CharacterCard, book: Book, chapter: Int, language: Language) {
        self.character = character
        self.book = book
        self.chapter = chapter
        self.language = language
        self._viewModel = StateObject(
            wrappedValue: CharacterChatViewModel(
                character: character,
                book: book,
                chapter: chapter,
                language: language
            )
        )
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Character header
                characterHeader
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, Theme.Spacing.xs)

                Divider()

                // Message list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.sm) {
                            ForEach(viewModel.messages) { message in
                                CharacterChatBubble(
                                    message: message,
                                    characterName: character.fullName
                                )
                            }

                            // Suggested question chips —
                            // shown only before the user has sent their first message
                            if viewModel.messages.count == 1,
                               let questions = character.suggestedQuestions,
                               !questions.isEmpty {
                                suggestedChips(questions: questions)
                            }

                            // Error banner (network/auth errors)
                            if let error = viewModel.error {
                                errorBanner(error)
                            }

                            // Safety ended card
                            if viewModel.isSafetyEnded {
                                safetyEndedBanner
                            }

                            // Invisible anchor for auto-scroll
                            Color.clear
                                .frame(height: 1)
                                .id(bottomID)
                        }
                        .padding(.vertical, Theme.Spacing.sm)
                    }
                    .onChange(of: viewModel.messages.count) {
                        withAnimation { proxy.scrollTo(bottomID, anchor: .bottom) }
                    }
                    .onChange(of: viewModel.messages.last?.content) {
                        // Also scroll during streaming as content grows
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }

                // Input bar — disabled when at limit, safety ended, or streaming
                CharacterChatInputBar(
                    text: $viewModel.inputText,
                    isDisabled: viewModel.isAtLimit || viewModel.isSafetyEnded,
                    onSend: viewModel.sendMessage
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showReport = true
                    } label: {
                        Image(systemName: "flag")
                            .foregroundColor(Theme.Colors.error)
                    }
                }
            }
        }
        .onAppear {
            if !hasSeenChatDisclaimer {
                showDisclaimer = true
            }
        }
        // Disclaimer — blocks all interaction until accepted
        .fullScreenCover(isPresented: $showDisclaimer) {
            CharacterChatDisclaimerView {
                hasSeenChatDisclaimer = true
                showDisclaimer = false
            }
        }
        // Report sheet
        .sheet(isPresented: $showReport) {
            ReportSheetView(characterName: character.fullName) { reason, detail in
                Task {
                    await viewModel.submitReport(reason: reason, detail: detail)
                    // Small delay so user sees confirmation before dismiss
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    dismiss()
                }
            }
        }
    }

    // MARK: - Character Header

    private var characterHeader: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Avatar
            Circle()
                .fill(Theme.Colors.brandGradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(character.fullName.prefix(1)).uppercased())
                        .font(.headline.bold())
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(character.fullName)
                    .font(.headline)
                Text(character.role ?? "Character")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Chapter badge
            Text("Ch. \(chapter)")
                .font(.caption.bold())
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.15))
                .foregroundColor(.green)
                .cornerRadius(Theme.CornerRadius.sm)
        }
    }

    // MARK: - Suggested Chips

    private func suggestedChips(questions: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(questions, id: \.self) { question in
                    Button {
                        viewModel.inputText = question
                        viewModel.sendMessage()
                    } label: {
                        Text(question)
                            .font(.caption)
                            .foregroundColor(Theme.Colors.primary)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(Theme.Colors.primary.opacity(0.1))
                            .cornerRadius(Theme.CornerRadius.lg)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "wifi.exclamationmark")
                .font(.caption)
            Text(message)
                .font(.caption)
            Spacer()
            Button("Retry") {
                viewModel.error = nil
                viewModel.sendMessage()
            }
            .font(.caption.bold())
        }
        .foregroundColor(Theme.Colors.error)
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.error.opacity(0.08))
        .cornerRadius(Theme.CornerRadius.md)
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Safety Ended Banner

    private var safetyEndedBanner: some View {
        Text("This conversation has ended.")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - CharacterChatDisclaimerView

struct CharacterChatDisclaimerView: View {
    let onAccept: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            Image(systemName: "shield.checkered")
                .font(.system(size: 56))
                .foregroundStyle(Theme.Colors.brandGradient)

            VStack(spacing: Theme.Spacing.sm) {
                Text("Before You Chat")
                    .font(.title2.bold())

                Text("Character Chat uses AI to bring fictional characters to life. Responses are generated and may occasionally be unexpected.\n\nThis feature is intended for readers exploring story and character, not for harmful or off-topic conversations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.md)
            }

            VStack(spacing: Theme.Spacing.xs) {
                Button {
                    openURL(URL(string: "https://bookcompanion-api.vercel.app/safety")!)
                } label: {
                    Text("Safety Guidelines")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.primary)
                }

                Button {
                    openURL(URL(string: "https://bookcompanion-api.vercel.app/privacy")!)
                } label: {
                    Text("Privacy Policy")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.primary)
                }
            }

            Spacer()

            Button(action: onAccept) {
                Text("I understand — Start Chatting")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Colors.brandGradient)
                    .cornerRadius(Theme.CornerRadius.lg)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .interactiveDismissDisabled(true)   // must tap the CTA, no swipe-to-dismiss
    }
}

// MARK: - ReportSheetView

struct ReportSheetView: View {
    let characterName: String
    let onSubmit: (String, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason = "Inappropriate content"
    @State private var detail = ""
    @State private var submitted = false

    private let reasons = [
        "Inappropriate content",
        "Unsafe response",
        "Other"
    ]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                if submitted {
                    // Confirmation state
                    VStack(spacing: Theme.Spacing.md) {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.success)
                        Text("Thanks for reporting.")
                            .font(.headline)
                        Text("We'll review this conversation.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // Report form
                    Text("What's the issue with this conversation?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, Theme.Spacing.md)

                    Picker("Reason", selection: $selectedReason) {
                        ForEach(reasons, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Additional detail (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, Theme.Spacing.md)

                        TextEditor(text: $detail)
                            .font(.subheadline)
                            .frame(height: 80)
                            .padding(Theme.Spacing.xs)
                            .background(Color(.systemGray6))
                            .cornerRadius(Theme.CornerRadius.md)
                            .padding(.horizontal, Theme.Spacing.md)
                            .onChange(of: detail) {
                                if detail.count > 200 { detail = String(detail.prefix(200)) }
                            }
                    }

                    Spacer()

                    Button {
                        submitted = true
                        onSubmit(selectedReason, detail.isEmpty ? nil : detail)
                    } label: {
                        Text("Submit Report")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Theme.Colors.error)
                            .cornerRadius(Theme.CornerRadius.lg)
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .padding(.top, Theme.Spacing.lg)
            .navigationTitle("Report Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
