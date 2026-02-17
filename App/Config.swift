//
//  Config.swift
//  BookCompanion
//
//  Created by Shree on 06/02/2026.
//

import Foundation

enum Config {
    
    // MARK: - API Configuration
    
#if DEBUG
// Development
static let apiEndpoint = "https://bookcompanion-api.vercel.app"
static let appSecret = "ujxlv2MWUY/EyRV+0Rc20eGjca8GqN5V3Q5oEnuedjM="
#else
// Production
static let apiEndpoint = "https://bookcompanion-api.vercel.app"
static let appSecret = "ujxlv2MWUY/EyRV+0Rc20eGjca8GqN5V3Q5oEnuedjM="
#endif
    
    // MARK: - App Information
    
    static let appVersion = "1.0.0"
    static let appName = "BookCompanion"
    
    // MARK: - Limits
    
    static let maxChapters = 500
    static let summaryTimeoutSeconds: Double = 30
}
