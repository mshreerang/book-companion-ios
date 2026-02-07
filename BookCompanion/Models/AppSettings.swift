//
//  AppSettings.swift
//  BookCompanion
//
//  Created by Shree on 04/02/2026.
//

import Foundation

struct AppSettings: Codable {
    var isAIEnabled: Bool
    
    static let `default` = AppSettings(
        isAIEnabled: false  // Offline by default
    )
}
