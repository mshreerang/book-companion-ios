//
//  CheckboxToggleStyle.swift
//  BookCompanion
//
//  Created by Shree on 25/02/2026.
//

import SwiftUI

struct CheckboxToggleStyle: ToggleStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        Button {
            guard isEnabled else { return }
            configuration.isOn.toggle()
            if configuration.isOn {
                HapticManager.lightImpact()
            }
        } label: {
            HStack(spacing: 12) {
                // The Checkbox Visual
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(configuration.isOn ? Color.blue : Color.secondary.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(configuration.isOn ? Color.blue.opacity(0.1) : Color.clear)
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
                    
                    if configuration.isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 44, height: 44) // Larger touch target
                .contentShape(Rectangle())
                
                configuration.label
                    .font(.body)
                    .foregroundColor(isEnabled ? .primary : .secondary)
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1.0 : 0.5)
        .allowsHitTesting(isEnabled)
        .contentShape(Rectangle()) // Makes entire row tappable
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(configuration.isOn ? [.isButton, .isSelected] : .isButton)
    }
}
