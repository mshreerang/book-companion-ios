//
//  Theme.swift
//  BookCompanion
//
//  Created by Shree on 08/02/2026.
//  Updated: brand palette changed from blue/purple to indigo/teal
//           to distinguish from AI-generated app defaults.
//

import SwiftUI

// MARK: - App Theme

enum Theme {

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat  =  4
        static let xs:  CGFloat  =  8
        static let sm:  CGFloat  = 12
        static let md:  CGFloat  = 16
        static let lg:  CGFloat  = 20
        static let xl:  CGFloat  = 24
        static let xxl: CGFloat  = 32
        static let xxxl: CGFloat = 40
    }

    // MARK: - Corner Radius
    // Use these everywhere — never hardcode values in views.
    // xs  = chips/tags   sm = inner elements   md = inputs/rows
    // lg  = buttons      xl = cards

    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
    }

    // MARK: - Colors

    enum Colors {

        // ── Brand palette ──────────────────────────────────────────────
        // Indigo → Teal: literary, calm, premium.
        // Chosen to stand apart from the ubiquitous AI blue/purple default
        // (Tailwind's bg-indigo-500 that all LLM-generated UIs default to).

        static let primary   = Color(red: 0.29, green: 0.33, blue: 0.73)  // indigo
        static let secondary = Color(red: 0.18, green: 0.64, blue: 0.60)  // teal

        // Gradient colours
        static let gradientStart = Color(red: 0.29, green: 0.33, blue: 0.73) // indigo
        static let gradientEnd   = Color(red: 0.18, green: 0.64, blue: 0.60) // teal

        /// Standard horizontal button/icon gradient (leading → trailing)
        static var brandGradient: LinearGradient {
            LinearGradient(
                colors: [gradientStart, gradientEnd],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        /// Diagonal variant for large hero areas (onboarding icons, etc.)
        static var brandGradientDiagonal: LinearGradient {
            LinearGradient(
                colors: [gradientStart, gradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // ── Mode colours ───────────────────────────────────────────────
        static let aiMode      = Color(red: 0.29, green: 0.33, blue: 0.73) // indigo
        static let offlineMode = Color(red: 0.18, green: 0.64, blue: 0.60) // teal

        // ── Status colours ─────────────────────────────────────────────
        static let success = Color.green
        static let warning = Color.orange
        static let error   = Color.red

        // ── Neutral colours ────────────────────────────────────────────
        static let textPrimary         = Color.primary
        static let textSecondary       = Color.secondary
        static let background          = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)

        // ── Shadow tint ────────────────────────────────────────────────
        // Use this instead of .blue.opacity(0.3) for brand-consistent shadows.
        static let brandShadow = Color(red: 0.29, green: 0.33, blue: 0.73).opacity(0.28)
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle:  Font = .largeTitle.weight(.bold)
        static let title:       Font = .title.weight(.bold)
        static let title2:      Font = .title2.weight(.bold)
        static let title3:      Font = .title3.weight(.semibold)
        static let headline:    Font = .headline
        static let body:        Font = .body
        static let callout:     Font = .callout
        static let subheadline: Font = .subheadline
        static let footnote:    Font = .footnote
        static let caption:     Font = .caption
        static let caption2:    Font = .caption2
    }

    // MARK: - Shadows

    enum Shadow {
        static let sm = (color: Color.black.opacity(0.08),  radius: CGFloat(4),  x: CGFloat(0), y: CGFloat(2))
        static let md = (color: Color.black.opacity(0.12),  radius: CGFloat(8),  x: CGFloat(0), y: CGFloat(4))
        static let lg = (color: Color.black.opacity(0.16),  radius: CGFloat(12), x: CGFloat(0), y: CGFloat(6))
        static let brand = (color: Theme.Colors.brandShadow, radius: CGFloat(10), x: CGFloat(0), y: CGFloat(5))
    }

    // MARK: - Icons

    enum Icons {
        // App features
        static let book      = "book.closed.fill"
        static let bookPages = "book.pages"
        static let characters = "person.2.fill"
        static let listen    = "speaker.wave.2.fill"
        static let stop      = "stop.fill"

        // Modes
        static let aiMode      = "sparkles"
        static let offlineMode = "airplane"

        // Actions
        static let add      = "plus"
        static let delete   = "trash"
        static let search   = "magnifyingglass"
        static let settings = "gear"
        static let share    = "square.and.arrow.up"

        // Status
        static let success = "checkmark.circle.fill"
        static let error   = "exclamationmark.triangle.fill"
        static let loading = "hourglass"

        // Navigation
        static let back    = "chevron.left"
        static let forward = "chevron.right"
        static let external = "arrow.up.forward"
    }

    // MARK: - Sizes

    enum Size {
        static let coverWidth:  CGFloat = 60
        static let coverHeight: CGFloat = 90

        static let avatarSmall:  CGFloat = 40
        static let avatarMedium: CGFloat = 60
        static let avatarLarge:  CGFloat = 80

        static let iconSmall:  CGFloat = 16
        static let iconMedium: CGFloat = 24
        static let iconLarge:  CGFloat = 32
    }
}

// MARK: - View Extensions

extension View {

    /// Applies the standard brand gradient as a foreground style.
    func brandGradient() -> some View {
        self.foregroundStyle(Theme.Colors.brandGradient)
    }

    /// Applies the diagonal brand gradient (for large hero icons).
    func brandGradientDiagonal() -> some View {
        self.foregroundStyle(Theme.Colors.brandGradientDiagonal)
    }

    /// Applies Theme.CornerRadius.md (8pt) — use for inputs and rows.
    func standardCornerRadius() -> some View {
        self.cornerRadius(Theme.CornerRadius.md)
    }

    /// Applies Theme.CornerRadius.xl (16pt) — use for cards.
    func cardCornerRadius() -> some View {
        self.cornerRadius(Theme.CornerRadius.xl)
    }

    /// Applies the standard drop shadow.
    func standardShadow() -> some View {
        let s = Theme.Shadow.md
        return self.shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }

    /// Applies a brand-tinted shadow — use on primary CTA buttons.
    func brandShadow() -> some View {
        let s = Theme.Shadow.brand
        return self.shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }
}

// MARK: - Brand Gradient Button Style
// Convenience: apply to any Button to get the full indigo→teal pill treatment.

struct BrandGradientButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isEnabled {
                        Theme.Colors.brandGradient
                    } else {
                        LinearGradient(colors: [.gray, .gray],
                                       startPoint: .leading, endPoint: .trailing)
                    }
                }
            )
            .cornerRadius(Theme.CornerRadius.xl)
            .shadow(color: isEnabled ? Theme.Colors.brandShadow : .clear,
                    radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
