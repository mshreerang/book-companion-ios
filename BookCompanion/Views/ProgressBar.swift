//
//  ProgressBar.swift
//  BookCompanion
//
//  Created on 15/02/2026.
//
import SwiftUI

struct ProgressBar: View {
    let progress: Double // 0.0 to 1.0
    let height: CGFloat
    let showPercentage: Bool
    
    init(
        progress: Double,
        height: CGFloat = 6,
        showPercentage: Bool = false
    ) {
        self.progress = progress
        self.height = height
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: height)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                colors: progressColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: height)
                }
            }
            .frame(height: height)
            
            // Percentage text (optional)
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 35, alignment: .trailing)
            }
        }
    }
    
    // Color gradient based on progress
    private var progressColors: [Color] {
        switch progress {
        case 0..<0.33:
            return [Color.blue, Color.cyan]
        case 0.33..<0.66:
            return [Color.orange, Color.yellow]
        case 0.66...1.0:
            return [Color.green, Color.mint]
        default:
            return [Color.gray]
        }
    }
}
