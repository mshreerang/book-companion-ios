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
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: height)
                    
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress, height: height)
                }
            }
            .frame(height: height)
            
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 35, alignment: .trailing)
            }
        }
    }
    
    // Single flat colour based on progress — no gradient.
    // Low: terracotta warning tone. Mid/high: primary green.
    private var progressColor: Color {
        switch progress {
        case 0..<0.33:
            return Theme.Colors.secondary       // terracotta — early progress
        case 0.33..<0.80:
            return Theme.Colors.primary         // forest green — good progress
        case 0.80...1.0:
            return Theme.Colors.primary         // forest green — near/complete
        default:
            return Color(UIColor.systemGray3)
        }
    }
}
