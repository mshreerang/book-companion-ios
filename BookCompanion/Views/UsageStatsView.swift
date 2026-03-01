
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
    
    var body: some View {
        List {
            // ✅ CURRENT USAGE
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
                            Text("\(viewModel.summariesUsed) / \(viewModel.summariesLimit)")
                                .font(.title2.bold())
                        }
                    }
                    
                    Spacer()
                    
                    // Progress circle
                    if !viewModel.isLoading {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .trim(from: 0, to: viewModel.usageProgress)
                                .stroke(
                                    viewModel.isNearLimit ? Color.orange : Color.blue,
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: viewModel.usageProgress)
                            
                            Text("\(Int(viewModel.usageProgress * 100))%")
                                .font(.caption.bold())
                                .foregroundColor(viewModel.isNearLimit ? .orange : .blue)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // Remaining
                if !viewModel.isLoading {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.green)
                        Text("\(viewModel.summariesRemaining) summaries remaining this month")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("This Month")
            } footer: {
                if viewModel.isNearLimit {
                    Text("You're running low! Upgrade to Pro for unlimited summaries.")
                        .foregroundColor(.orange)
                } else if viewModel.isAtLimit {
                    Text("Quota reached. Resets next month or upgrade to Pro.")
                        .foregroundColor(.red)
                }
            }
            
            // ✅ SUBSCRIPTION TIER
            Section {
                HStack {
                    Image(systemName: viewModel.isPro ? "crown.fill" : "person.fill")
                        .foregroundColor(viewModel.isPro ? .yellow : .gray)
                    
                    Text(viewModel.isPro ? "Pro" : "Free")
                        .font(.headline)
                    
                    Spacer()
                    
                    if !viewModel.isPro {
                        NavigationLink(destination: UpgradeView()) {
                            Text("Upgrade")
                        }
                    }
                }
            } header: {
                Text("Subscription")
            }
            
            // ✅ PERIOD INFO
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
            
            // ✅ ERROR STATE
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
    
    var summariesRemaining: Int {
        max(0, summariesLimit - summariesUsed)
    }
    
    var usageProgress: Double {
        guard summariesLimit > 0 else { return 0 }
        return Double(summariesUsed) / Double(summariesLimit)
    }
    
    var isNearLimit: Bool {
        usageProgress >= 0.8 && !isAtLimit
    }
    
    var isAtLimit: Bool {
        summariesUsed >= summariesLimit
    }
    
    var resetDate: String {
        // Next month, 1st day
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
            
            self.summariesUsed = stats.summaries_generated
            self.summariesLimit = stats.summaries_limit
            self.currentPeriod = stats.period
            self.isPro = stats.tier == "pro"
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

// ============================================
// MARK: - Upgrade View (Placeholder)
// ============================================

struct UpgradeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Upgrade to Pro")
                .font(.title.bold())
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "infinity", text: "Unlimited summaries")
                FeatureRow(icon: "person.2.fill", text: "Unlimited character analysis")
                FeatureRow(icon: "books.vertical.fill", text: "Unlimited books")
                FeatureRow(icon: "sparkles", text: "Priority support")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            Button {
                // TODO: Implement IAP
            } label: {
                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(12)
            }
            .disabled(true)
        }
        .padding()
        .navigationTitle("Pro")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
}

#Preview {
    NavigationStack {
        UsageStatsView()
    }
}
