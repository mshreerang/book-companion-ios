//
//  SettingsView.swift
//  BookCompanion
//
//  Updated 2026: removed AI mode toggle (offline mode was a dev tool,
//  not a user feature — 100% of features need AI), restructured sections
//  to Account → App → About, added Replay Walkthrough, fixed legal URLs,
//  App Store link placeholder ready to swap on launch.
//

import SwiftUI


private let appStoreURL = URL(string: "https://apps.apple.com/gb/app/bookcompanion-ai/id6759411769")!
// ─────────────────────────────────────────────────────────────────────────────

struct SettingsView: View {

    @ObservedObject var settingsManager: SettingsManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false
    @State private var showDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    var body: some View {
        NavigationStack {
            List {

                // ── 1. Account ─────────────────────────────────────────
                Section {

                    if GuestManager.shared.isGuestMode {
                        // ── Guest mode: simple sign-up prompt ─────────────
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray4))
                                    .frame(width: 56, height: 56)
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Guest")
                                    .font(.headline)
                                Text("Create an account to save your progress")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)

                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                GuestManager.shared.exitGuestMode()
                            }
                        } label: {
                            HStack {
                                Label("Create Free Account", systemImage: "person.crop.circle.badge.plus")
                                    .foregroundStyle(Theme.Colors.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                GuestManager.shared.exitGuestMode()
                            }
                        } label: {
                            Label("Sign In", systemImage: "person.crop.circle")
                        }

                    } else {
                    // ── Signed-in user: full account section ──────────────

                    // Profile row
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.brandGradientDiagonal)
                                .frame(width: 56, height: 56)
                            Text(userInitials)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(authManager.userName ?? "User")
                                    .font(.headline)
                                if storeManager.isPro {
                                    Label("Pro", systemImage: "crown.fill")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange)
                                        .cornerRadius(Theme.CornerRadius.sm)
                                }
                            }
                            Text(authManager.userEmail ?? "Not signed in")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    // Usage — "Monthly Starter Pack" framing matches onboarding
                    NavigationLink {
                        UsageStatsView()
                    } label: {
                        HStack {
                            Label("Usage", systemImage: "chart.bar.fill")
                            Spacer()
                            if !storeManager.isPro {
                                Text("Free")
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.Colors.secondary)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Theme.Colors.secondary.opacity(0.12))
                                    .cornerRadius(Theme.CornerRadius.xs)
                            }
                        }
                    }

                    // Pro management
                    if storeManager.isPro {
                        Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                            HStack {
                                Label("Manage Subscription", systemImage: "creditcard")
                                Spacer()
                                Image(systemName: "arrow.up.forward")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Button { showPaywall = true } label: {
                            HStack {
                                Label("Buy Credits or Upgrade to Pro", systemImage: "crown.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Sign Out — inside Account, not isolated at the bottom
                    Button(role: .destructive) {
                        authManager.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }

                    // Delete Account — required by App Store guideline 5.1.1(v)
                    Button(role: .destructive) {
                        showDeleteAccountAlert = true
                    } label: {
                        Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                    }

                    } // end else (signed-in)

                } header: {
                    Text("Account")
                }

                // ── 2. About ───────────────────────────────────────────
                Section {

                    // Replay Walkthrough
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            hasCompletedOnboarding = false
                        }
                    } label: {
                        Label("Replay Walkthrough", systemImage: "arrow.counterclockwise")
                    }

                    // Privacy Policy — updated to book-companion-docs
                    Link(destination: URL(string: "https://mshreerang.github.io/book-companion-docs/privacy-policy.html")!) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Support
                    Link(destination: URL(string: "mailto:support@vivanlabs.com")!) {
                        HStack {
                            Label("Support", systemImage: "questionmark.circle")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Share App — swap appStoreURL constant when live
                    ShareLink(
                        item: appStoreURL,
                        subject: Text("BookCompanion AI"),
                        message: Text("Never lose your place in a book again — BookCompanion gives you AI summaries and character guides, spoiler-free.")
                    ) {
                        Label("Share App", systemImage: "square.and.arrow.up")
                    }

                } header: {
                    Text("About")
                }

                // ── Version footer ─────────────────────────────────────
                Section {} footer: {
                    VStack(spacing: 4) {
                        Text("Version \(appVersion) (\(buildNumber))")
                        Text("Made with ❤️ in London")
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(storeManager)
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Account", role: .destructive) {
                    Task { await deleteAccount() }
                }
            } message: {
                Text("This will permanently delete your account and all data — your library, reading progress and chat history cannot be recovered.\n\nIf you have an active Pro subscription, please cancel it via Apple ID Account Settings before deleting to avoid future charges. If you rejoin later, your subscription may restore automatically but your library will not.")
            }
            .overlay {
                if isDeletingAccount {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.4)
                                .tint(.white)
                            Text("Deleting account…")
                                .foregroundColor(.white)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func deleteAccount() async {
        isDeletingAccount = true
        do {
            guard let token = KeychainManager.shared.getUserToken() else {
                isDeletingAccount = false
                return
            }
            let url = URL(string: "\(Config.apiEndpoint)/api/auth/delete-account")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                await MainActor.run {
                    isDeletingAccount = false
                    authManager.signOut()
                }
            } else {
                await MainActor.run { isDeletingAccount = false }
            }
        } catch {
            await MainActor.run { isDeletingAccount = false }
            print("❌ Delete account error: \(error)")
        }
    }

    private var userInitials: String {
        guard let name = authManager.userName else { return "?" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts.first?.first ?? "?")\(parts.last?.first ?? "?")".uppercased()
        } else if let first = parts.first?.first {
            return String(first).uppercased()
        }
        return "?"
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

}

// MARK: - Global Helpers

func formatBytes(_ bytes: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useKB]
    formatter.countStyle = .file
    return bytes < 100_000 ? "Empty" : formatter.string(fromByteCount: Int64(bytes))
}

#Preview {
    SettingsView(settingsManager: SettingsManager())
        .environmentObject(AuthManager.shared)
        .environmentObject(StoreManager.shared)
}
