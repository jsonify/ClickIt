//
//  TabButton.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

struct TabButton: View {
    let tab: MainTab
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(iconColor)
                
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(backgroundView)
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("tab-\(tab.rawValue)")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        Group {
            if isSelected {
                Color.accentColor.opacity(0.1)
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(.accentColor),
                        alignment: .bottom
                    )
            } else if isHovered {
                Color(NSColor.controlAccentColor).opacity(0.05)
            } else {
                Color.clear
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
    
    private var iconColor: Color {
        if isSelected {
            return .accentColor
        } else if isHovered {
            return Color.primary.opacity(0.8)
        } else {
            return Color.primary.opacity(0.6)
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .accentColor
        } else if isHovered {
            return Color.primary.opacity(0.9)
        } else {
            return Color.primary.opacity(0.7)
        }
    }
}

// MARK: - Preview

struct TabButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 0) {
                TabButton(tab: .quickStart, isSelected: true) {}
                TabButton(tab: .presets, isSelected: false) {}
                TabButton(tab: .settings, isSelected: false) {}
                TabButton(tab: .statistics, isSelected: false) {}
                TabButton(tab: .advanced, isSelected: false) {}
            }
            .background(Color(NSColor.windowBackgroundColor))
            
            Text("Tab Buttons Preview")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 400)
        .padding()
    }
}