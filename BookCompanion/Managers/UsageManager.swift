//
//  UsageManager.swift
//  BookCompanion
//
//  Created by Shree on 23/04/2026.
//
//  Single source of truth for monthly usage counts.
//  Populated on sign-in and refreshed after each summary generation.
//  Read by ProgressInputView to show the quota warning banner.

import Foundation
import Combine

@MainActor
final class UsageManager: ObservableObject {
    
    static let shared = UsageManager()
    private init() {}
    
    // Monthly usage — summaries only for now (most important for quota warning)
    @Published private(set) var summariesUsed: Int = 0
    @Published private(set) var summariesLimit: Int = 0  // 0 until first refresh
    @Published private(set) var isPro: Bool = false
    
    // Derived
    var summariesRemaining: Int { max(0, summariesLimit - summariesUsed) }
    //var isNearLimit: Bool{true}
    var isNearLimit: Bool { !isPro && summariesUsed >= summariesLimit - 1 && summariesUsed < summariesLimit }
    var isAtLimit: Bool { !isPro && summariesUsed >= summariesLimit }
    
    // MARK: - Fetch
    
    /// Call on sign-in and after every summary generation.
    func refresh() {
        Task { await load() }
    }
    
    private func load() async {
        guard let token = KeychainManager.shared.getUserToken() else { return }
        guard let url = URL(string: "\(Config.apiEndpoint)/api/usage/stats") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            
            summariesUsed  = json["summaries_generated"] as? Int ?? 0
            summariesLimit = json["summaries_limit"]     as? Int ?? 5
            isPro          = (json["tier"] as? String)   == "pro"
        } catch {
            // Non-fatal — UI degrades gracefully if counts unavailable
            print("⚠️ UsageManager.load failed: \(error)")
        }
    }
    
    // MARK: - Local update (optimistic, after generation)
    // Called immediately after a summary is generated so the UI
    // updates without waiting for a network round-trip.
    
    func incrementSummariesUsed() {
        guard !isPro else { return }
        summariesUsed = min(summariesUsed + 1, summariesLimit)
    }
    func update(used: Int, limit: Int) {
        summariesUsed  = used
        summariesLimit = limit
        if !isPro {
            NotificationManager.shared.scheduleQuotaWarning(used: used, limit: limit)
        }
    }
}
