//
//  UsageStatsView.swift
//  BookCompanion
//
//  Created by Shree on 22/02/2026.
//

import SwiftUI
import Combine

struct UsageStatsView: View {
    
    @StateObject private var viewModel = UsageStatsViewModel()
    @State private var showPaywall = false
    
    var body: some View {
        List {
            // CURRENT USAGE
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Summaries Generated")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text(viewModel.isPro
                                 ? "\(viewModel.summariesUsed) / \(viewModel.summariesLimit) per month"
                                 : "\(viewModel.summariesUsed) / \(viewModel.summariesLimit)")
                                .font(.title2.bold())
                        }
                    }
                    
                    Spacer()
                    
                    if !viewModel.isLoading {
                        if viewModel.isPro {
                            Image(systemName: "infinity")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(Theme.Colors.brandGradient)
                                .frame(width: 60, height: 60)
                        } else {
                            ZStack {
                                Circle()
                                    .stroke(Color(.systemGray5), lineWidth: 8)
                                    .frame(width: 60, height: 60)
                                
                                Circle()
                                    .trim(from: 0, to: viewModel.usageProgress)
                                    .stroke(
                                        viewModel.isNearLimit
                                            ? Theme.Colors.secondary
                                            : Theme.Colors.primary,
                                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                    )
                                    .frame(width: 60, height: 60)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut, value: viewModel.usageProgress)
                                
                                Text("\(Int(viewModel.usageProgress * 100))%")
                                    .font(.caption.bold())
                                    .foregroundColor(viewModel.isNearLimit
                                                     ? Theme.Colors.secondary
                                                     : Theme.Colors.primary)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                
                if !viewModel.isLoading {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(Theme.Colors.primary)
                        Text(viewModel.isPro
                             ? "\(viewModel.summariesRemaining) summaries remaining this month"
                             : "\(viewModel.summariesRemaining) summaries remaining this month")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("This Month")
            } footer: {
                if !viewModel.isPro {
                    if viewModel.isNearLimit {
                        Text("You're running low! Upgrade to Pro for unlimited summaries.")
                            .foregroundColor(.orange)
                    } else if viewModel.isAtLimit {
                        Text("Quota reached. Resets next month or upgrade to Pro.")
                            .foregroundColor(.red)
                    }
                }
            }

            // TOP-UP CREDITS — shown only for free users who have credits
            if !viewModel.isPro && viewModel.hasTopupCredits {
                Section {
                    topupCreditRow(
                        icon: "text.book.closed.fill",
                        label: "Summary Credits",
                        count: viewModel.topupSummaryCredits
                    )
                    topupCreditRow(
                        icon: "sparkles",
                        label: "Character Analysis Credits",
                        count: viewModel.topupCharacterCredits
                    )
                    topupCreditRow(
                        icon: "bubble.left.and.bubble.right.fill",
                        label: "Chat Message Credits",
                        count: viewModel.topupChatCredits
                    )
                } header: {
                    Text("Top-Up Credits")
                } footer: {
                    Text("These never expire and are used after your monthly allowance runs out.")
                        .foregroundColor(.secondary)
                }
            }
            
            // SUBSCRIPTION TIER
            Section {
                HStack {
                    Image(systemName: viewModel.isPro ? "crown.fill" : "person.fill")
                        .foregroundColor(viewModel.isPro ? .yellow : Color(.systemGray3))
                    
                    Text(viewModel.isPro ? "Pro" : "Free")
                        .font(.headline)
                    
                    Spacer()
                    
                    if !viewModel.isPro {
                        Button("Upgrade") {
                            showPaywall = true
                        }
                        .foregroundStyle(Theme.Colors.primary)
                    }
                }
            } header: {
                Text("Subscription")
            }
            
            // PERIOD INFO
            Section {
                HStack {
                    Text("Current Period")
                    Spacer()
                    Text(viewModel.currentPeriod)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Resets On")
                    Spacer()
                    Text(viewModel.resetDate)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Billing Period")
            }
            
            // ERROR STATE
            if let error = viewModel.error {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Usage")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadUsage()
        }
        .task {
            await viewModel.loadUsage()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func topupCreditRow(icon: String, label: String, count: Int) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Theme.Colors.primary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("\(count)")
                .font(.subheadline.bold())
                .foregroundStyle(count > 0 ? Theme.Colors.secondary : Color.secondary)
        }
    }
}

// ============================================
// MARK: - ViewModel
// ============================================

@MainActor
class UsageStatsViewModel: ObservableObject {
    
    @Published var summariesUsed = 0
    @Published var summariesLimit = 5
    @Published var currentPeriod = ""
    @Published var isPro = false
    @Published var isLoading = false
    @Published var error: String?

    @Published var topupSummaryCredits:   Int = 0
    @Published var topupCharacterCredits: Int = 0
    @Published var topupChatCredits:      Int = 0

    var hasTopupCredits: Bool {
        topupSummaryCredits > 0 || topupCharacterCredits > 0 || topupChatCredits > 0
    }
    
    var summariesRemaining: Int {
        max(0, summariesLimit - summariesUsed)
    }
    
    var usageProgress: Double {
        guard summariesLimit > 0 else { return 0 }
        return min(1.0, Double(summariesUsed) / Double(summariesLimit))
    }
    
    var isNearLimit: Bool {
        usageProgress >= 0.8 && !isAtLimit
    }
    
    var isAtLimit: Bool {
        summariesUsed >= summariesLimit
    }
    
    var resetDate: String {
        let calendar = Calendar.current
        let now = Date()
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: now),
           let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: firstDay)
        }
        return "Next month"
    }
    
    func loadUsage() async {
        isLoading = true
        error = nil
        
        do {
            guard let token = KeychainManager.shared.getUserToken() else {
                throw UsageError.notAuthenticated
            }
            
            let url = URL(string: "\(Config.apiEndpoint)/api/usage/stats")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw UsageError.requestFailed
            }
            
            let stats = try JSONDecoder().decode(UsageStats.self, from: data)
            
            self.summariesUsed   = stats.summaries_generated
            self.summariesLimit  = stats.summaries_limit
            self.currentPeriod   = stats.period
            self.isPro           = stats.tier == "pro"

            self.topupSummaryCredits   = stats.topup_summary_credits   ?? 0
            self.topupCharacterCredits = stats.topup_character_credits ?? 0
            self.topupChatCredits      = stats.topup_chat_credits      ?? 0

            StoreManager.shared.topupSummaryCredits   = self.topupSummaryCredits
            StoreManager.shared.topupCharacterCredits = self.topupCharacterCredits
            StoreManager.shared.topupChatCredits      = self.topupChatCredits

            self.isLoading = false
            
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
            print("❌ Error loading usage:", error)
        }
    }
}

// ============================================
// MARK: - Models
// ============================================

struct UsageStats: Codable {
    let summaries_generated: Int
    let summaries_limit: Int
    let period: String
    let tier: String
    let topup_summary_credits:   Int?
    let topup_character_credits: Int?
    let topup_chat_credits:      Int?
}

enum UsageError: LocalizedError {
    case notAuthenticated
    case requestFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to view usage"
        case .requestFailed:
            return "Failed to load usage stats"
        }
    }
}

#Preview {
    NavigationStack {
        UsageStatsView()
    }
}
