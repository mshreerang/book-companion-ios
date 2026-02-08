//
//  SettingsView.swift
//  BookCompanion
//
//  Created by Shree on 22/01/2026.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // App Mode Section - WITH ICONS
                Section {
                    Toggle(isOn: $settingsManager.settings.isAIEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: settingsManager.settings.isAIEnabled ? "sparkles" : "airplane")
                                .foregroundColor(settingsManager.settings.isAIEnabled ? .purple : .blue)
                                .font(.title3)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(settingsManager.settings.isAIEnabled ? "AI Mode" : "Offline Mode")
                                    .font(.headline)
                                
                                Text(settingsManager.settings.isAIEnabled ?
                                     "Personalized summaries for any book" :
                                     "Sample data only, no internet needed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Summary Mode")
                } footer: {
                    Text(settingsManager.settings.isAIEnabled ?
                         "AI generates custom summaries for your books. Requires internet connection." :
                         "View sample summaries without AI. Perfect for testing the app.")
                }
                
                // About Section - WITH ICONS
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Build", systemImage: "hammer")
                        Spacer()
                        Text(buildNumber)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
                
                // Legal Section - WITH ICONS AND SHARE
                Section {
                    Link(destination: URL(string: "https://bookcompanion-api.vercel.app/privacy.html")!) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "mailto:shreesanjeevmahale@gmail.com")!) {
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
                        Label("Share BookCompanion", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("Legal & Support")
                }
                
                // App Info Section - WITH GRADIENT ICON
                Section {
                    VStack(spacing: 16) {
                        // App Icon with Gradient
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        // App Name
                        Text("BookCompanion")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Tagline
                        Text("Never lose your place in a book again")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Made in India
                        HStack(spacing: 4) {
                            Text("Made with")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("❤️")
                                .font(.caption)
                            Text("in India")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
     
   
}
