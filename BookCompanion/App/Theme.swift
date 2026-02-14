//
//  Theme.swift
//  BookCompanion
//
//  Created by Shree on 08/02/2026.
//

import SwiftUI

// MARK: - App Theme

enum Theme {
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
    }
    
    // MARK: - Colors
    
    enum Colors {
        // Brand Colors
        static let primary = Color.blue
        static let secondary = Color.purple
        
        // Gradient
        static let gradientStart = Color.blue
        static let gradientEnd = Color.purple
        
        static var brandGradient: LinearGradient {
            LinearGradient(
                colors: [gradientStart, gradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        // Mode Colors
        static let aiMode = Color.purple
        static let offlineMode = Color.blue
        
        // Status Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        // Neutral Colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    }
    
    // MARK: - Typography
    
    enum Typography {
        // Title Styles
        static let largeTitle: Font = .largeTitle.weight(.bold)
        static let title: Font = .title.weight(.bold)
        static let title2: Font = .title2.weight(.bold)
        static let title3: Font = .title3.weight(.semibold)
        
        // Body Styles
        static let headline: Font = .headline
        static let body: Font = .body
        static let callout: Font = .callout
        static let subheadline: Font = .subheadline
        static let footnote: Font = .footnote
        static let caption: Font = .caption
        static let caption2: Font = .caption2
    }
    
    // MARK: - Shadows
    
    enum Shadow {
        static let sm = (color: Color.black.opacity(0.1), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let md = (color: Color.black.opacity(0.15), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let lg = (color: Color.black.opacity(0.2), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(6))
    }
    
    // MARK: - Icons
    
    enum Icons {
        // App Features
        static let book = "book.closed.fill"
        static let bookPages = "book.pages"
        static let characters = "person.2.fill"
        static let listen = "speaker.wave.2.fill"
        static let stop = "stop.fill"
        
        // Modes
        static let aiMode = "sparkles"
        static let offlineMode = "airplane"
        
        // Actions
        static let add = "plus"
        static let delete = "trash"
        static let search = "magnifyingglass"
        static let settings = "gear"
        static let share = "square.and.arrow.up"
        
        // Status
        static let success = "checkmark.circle.fill"
        static let error = "exclamationmark.triangle.fill"
        static let loading = "hourglass"
        
        // Navigation
        static let back = "chevron.left"
        static let forward = "chevron.right"
        static let external = "arrow.up.forward"
    }
    
    // MARK: - Sizes
    
    enum Size {
        // Book Cover
        static let coverWidth: CGFloat = 60
        static let coverHeight: CGFloat = 90
        
        // Character Avatar
        static let avatarSmall: CGFloat = 40
        static let avatarMedium: CGFloat = 60
        static let avatarLarge: CGFloat = 80
        
        // Icons
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 24
        static let iconLarge: CGFloat = 32
    }
}

// MARK: - View Extensions for Easy Access

extension View {
    
    // Spacing shortcuts
    func spacing(_ size: CGFloat) -> some View {
        self.padding(size)
    }
    
    // Brand gradient
    func brandGradient() -> some View {
        self.foregroundStyle(Theme.Colors.brandGradient)
    }
    
    // Standard corner radius
    func standardCornerRadius() -> some View {
        self.cornerRadius(Theme.CornerRadius.md)
    }
    
    // Standard shadow
    func standardShadow() -> some View {
        let shadow = Theme.Shadow.md
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
