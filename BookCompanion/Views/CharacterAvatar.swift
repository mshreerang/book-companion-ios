//
//  CharacterAvatar.swift
//  BookCompanion
//
//  Created by Shree on 07/02/2026.
//  Updated: replaced unstable hashValue (varies per launch in Swift)
//           with a stable UTF-8 byte-sum hash so every character
//           always gets the same colour across app launches.
//

import SwiftUI

struct CharacterAvatar: View {
    let name: String
    let size: CGFloat

    init(name: String, size: CGFloat = 60) {
        self.name = name
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: primaryColor.opacity(0.28), radius: 6, x: 0, y: 3)
    }

    // MARK: - Initials

    private var initials: String {
        let words = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        if words.count >= 2 {
            let first = words[0].prefix(1)
            let last  = words[words.count - 1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let firstWord = words.first {
            return String(firstWord.prefix(2)).uppercased()
        }
        return "??"
    }

    // MARK: - Stable colour selection
    //
    // Swift's hashValue is randomised per launch (hash seed randomisation).
    // Using it for colour selection means the same character can get a
    // different colour every time the app is opened — very jarring in a grid.
    //
    // Fix: sum the UTF-8 byte values of the name. This produces the same
    // integer for the same string on every launch, on every device.

    private var stableIndex: Int {
        let byteSum = name.utf8.reduce(0) { $0 &+ Int($1) }
        return abs(byteSum) % avatarColors.count
    }

    private var primaryColor: Color {
        avatarColors[stableIndex]
    }

    private var secondaryColor: Color {
        primaryColor.opacity(0.65)
    }

    // Deliberately avoiding blue/purple as dominant colours here since
    // they're overused in AI-adjacent apps. The palette leans toward
    // warm and distinctive hues.
    private let avatarColors: [Color] = [
        Color(red: 0.29, green: 0.33, blue: 0.73), // brand indigo
        Color(red: 0.18, green: 0.64, blue: 0.60), // brand teal
        Color(red: 0.85, green: 0.38, blue: 0.28), // coral
        Color(red: 0.20, green: 0.60, blue: 0.35), // forest green
        Color(red: 0.72, green: 0.35, blue: 0.68), // mauve
        Color(red: 0.88, green: 0.52, blue: 0.15), // amber
        Color(red: 0.25, green: 0.55, blue: 0.75), // steel blue
        Color(red: 0.60, green: 0.25, blue: 0.45), // wine
        Color(red: 0.30, green: 0.65, blue: 0.55), // sage
        Color(red: 0.75, green: 0.40, blue: 0.20), // burnt sienna
    ]
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            CharacterAvatar(name: "Jay Gatsby",      size: 64)
            CharacterAvatar(name: "Nick Carraway",   size: 64)
            CharacterAvatar(name: "Daisy Buchanan",  size: 64)
        }
        HStack(spacing: 12) {
            CharacterAvatar(name: "Tom Buchanan",    size: 48)
            CharacterAvatar(name: "Jordan Baker",    size: 48)
            CharacterAvatar(name: "Myrtle Wilson",   size: 48)
        }
    }
    .padding()
}
