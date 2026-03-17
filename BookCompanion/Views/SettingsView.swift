//
//  SettingsView.swift
//  BookCompanion
//
//  Updated by Shree on 22/02/2026.
//  Updated: removed branding header (wastes space, user knows the app),
//           replaced gmail support address with custom domain,
//           updated brand colours to indigo/teal,
//           toggle tint uses brand indigo instead of purple.
//

import SwiftUI

struct SettingsView: View {

    @ObservedObject var settingsManager: SettingsManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss

    @State private var cacheSize: Int = 0
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {

                // ── Account & Profile ──────────────────────────────────
                Section {
                    HStack(spacing: 16) {
                        // Initials avatar — brand gradient
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.brandGradientDiagonal)
                                .frame(width: 60, height: 60)

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

                    NavigationLink {
                        UsageStatsView()
                    } label: {
                        Label("Usage & Quota", systemImage: "chart.bar.fill")
                    }

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
                                Label("Upgrade to Pro", systemImage: "crown.fill")
                                    .foregroundStyle(
                                        LinearGradient(colors: [.yellow, .orange],
                                                       startPoint: .leading,
                                                       endPoint: .trailing)
                                    )
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Account")
                }

                // ── Summary Mode ───────────────────────────────────────
                Section {
                    Toggle(isOn: $settingsManager.settings.isAIEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(settingsManager.settings.isAIEnabled ? "AI Mode" : "Offline Mode")
                                    .font(.headline)

                                Text(settingsManager.settings.isAIEnabled
                                     ? "Personalised summaries for any book"
                                     : "Sample data only, no internet needed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: settingsManager.settings.isAIEnabled ? "sparkles" : "airplane")
                                .foregroundColor(settingsManager.settings.isAIEnabled
                                                 ? Theme.Colors.primary   // indigo
                                                 : Theme.Colors.secondary) // teal
                        }
                    }
                    // Toggle tint uses brand indigo, not generic purple
                    .tint(Theme.Colors.primary)
                } header: {
                    Text("Summary Mode")
                } footer: {
                    Text(settingsManager.settings.isAIEnabled
                         ? "AI generates custom summaries for your books. Requires internet connection."
                         : "View sample summaries without AI. Perfect for testing the app.")
                }

                // ── Storage ────────────────────────────────────────────
                Section {
                    NavigationLink {
                        StorageDetailView(cacheSize: $cacheSize)
                    } label: {
                        HStack {
                            Label("Storage", systemImage: "externaldrive.fill")
                            Spacer()
                            Text(formatBytes(cacheSize))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Storage")
                } footer: {
                    Text("Book cover images are cached locally (up to 100 MB)")
                }

                // ── Legal & Support ────────────────────────────────────
                Section {
                    if let url = URL(string: "https://mshreerang.github.io/book-companion-ios/privacy-policy.html") {
                        Link(destination: url) {
                            HStack {
                                Label("Privacy Policy", systemImage: "hand.raised")
                                Spacer()
                                Image(systemName: "arrow.up.forward")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Updated: custom domain email replaces personal Gmail
                    Link(destination: URL(string: "mailto:support@bookcompanion.app")!) {
                        HStack {
                            Label("Support", systemImage: "questionmark.circle")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    ShareLink(
                        item: URL(string: "https://apps.apple.com")!,
                        subject: Text("BookCompanion"),
                        message: Text("Check out BookCompanion - never lose your place in a book again!")
                    ) {
                        Label("Share App", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("Legal & Support")
                }

                // ── Destructive ────────────────────────────────────────
                Section {
                    Button(role: .destructive) {
                        authManager.signOut()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }

                // ── Version footer ─────────────────────────────────────
                Section {} footer: {
                    VStack(spacing: 4) {
                        Text("Version \(appVersion) (\(buildNumber))")
                        Text("Made with ❤️ in London")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { loadCacheSize() }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(storeManager)
            }
        }
    }

    // MARK: - Helpers

    private var userInitials: String {
        guard let name = authManager.userName else { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return "\(components.first?.first ?? "?")\(components.last?.first ?? "?")".uppercased()
        } else if let first = components.first?.first {
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

    private func loadCacheSize() {
        Task {
            let size = await CoverImageManager.shared.getTotalStorageUsed()
            await MainActor.run { cacheSize = size }
        }
    }
}

// MARK: - Global Helpers

func formatBytes(_ bytes: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useKB]
    formatter.countStyle = .file
    return bytes < 100_000 ? "Empty" : formatter.string(fromByteCount: Int64(bytes))
}

// MARK: - Storage Detail View

struct StorageDetailView: View {

    @Binding var cacheSize: Int
    @State private var showingClearAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Cover Images Cache", systemImage: "photo.stack")
                    Spacer()
                    Text(formatBytes(cacheSize))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Storage Usage")
            }

            Section {
                Button(role: .destructive) {
                    showingClearAlert = true
                } label: {
                    Label("Clear Cover Cache", systemImage: "trash")
                }
            } footer: {
                Text("This will remove all cached book cover images. They will be re-downloaded when needed.")
            }
        }
        .navigationTitle("Storage")
        .alert("Clear Cover Cache?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task { await clearCache() }
            }
        } message: {
            Text("This will delete all cached images (\(formatBytes(cacheSize))).")
        }
    }

    private func clearCache() async {
        await CoverImageManager.shared.clearAllCovers()
        HapticManager.success()
        let size = await CoverImageManager.shared.getTotalStorageUsed()
        await MainActor.run { cacheSize = size }
        try? await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run { dismiss() }
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager())
        .environmentObject(AuthManager.shared)
        .environmentObject(StoreManager.shared)
}
