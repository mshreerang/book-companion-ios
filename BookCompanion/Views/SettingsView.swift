//
//  SettingsView.swift
//  BookCompanion
//
//  Created by Shree on 04/02/2026.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        Form {
            
            // AI Mode Section
            Section {
                Toggle("Use AI Summaries", isOn: $settingsManager.settings.isAIEnabled)
                
                if settingsManager.settings.isAIEnabled {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.green)
                        Text("AI Mode Active")
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Image(systemName: "airplane")
                            .foregroundColor(.blue)
                        Text("Offline Mode")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Summary Generation")
            } footer: {
                if settingsManager.settings.isAIEnabled {
                    Text("AI mode generates personalized summaries for any book.")
                } else {
                    Text("Offline mode uses sample summaries and works without internet.")
                }
            }
            
            // About Section
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Config.appVersion)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView(settingsManager: SettingsManager())
    }
}
