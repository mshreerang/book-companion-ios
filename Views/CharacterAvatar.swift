//
//  CharacterAvatar.swift
//  BookCompanion
//
//  Created by Shree on 07/02/2026.
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
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Computed Properties
    
    private var initials: String {
        let words = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        if words.count >= 2 {
            // First name + Last name initials
            let first = words[0].prefix(1)
            let last = words[words.count - 1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let firstWord = words.first {
            // Single name - first 2 letters
            return String(firstWord.prefix(2)).uppercased()
        }
        
        return "??"
    }
    
    private var primaryColor: Color {
        let colors: [Color] = [
            .blue,
            .purple,
            .pink,
            .orange,
            .green,
            .red,
            .indigo,
            .cyan,
            .mint,
            .teal
        ]
        
        let index = abs(name.hashValue % colors.count)
        return colors[index]
    }
    
    private var secondaryColor: Color {
        primaryColor.opacity(0.7)
    }
}

#Preview {
    VStack(spacing: 20) {
        CharacterAvatar(name: "Jay Gatsby", size: 80)
        CharacterAvatar(name: "Nick Carraway", size: 60)
        CharacterAvatar(name: "Daisy", size: 50)
        CharacterAvatar(name: "Tom Buchanan", size: 40)
    }
    .padding()
}
