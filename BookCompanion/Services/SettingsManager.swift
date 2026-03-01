//
//  SettingsManager.swift
//  BookCompanion
//
//  Created by Shree on 04/02/2026.
//

import Foundation
import Combine 

final class SettingsManager: ObservableObject {
    
    @Published var settings: AppSettings {
        didSet {
            save()
        }
    }
    
    private let defaults = UserDefaults.standard
    private let key = "app_settings"
    
    init() {
        // Load saved settings or use default
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: key)
        }
    }
}
