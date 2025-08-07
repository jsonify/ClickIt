//
//  TabBarView.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: MainTab
    @FocusState private var focusedTab: MainTab?
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
                .focused($focusedTab, equals: tab)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
        .onKeyPress(.leftArrow) {
            navigateTab(direction: -1)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            navigateTab(direction: 1)
            return .handled
        }
        .onAppear {
            focusedTab = selectedTab
        }
        .onChange(of: selectedTab) { _, newValue in
            focusedTab = newValue
        }
    }
    
    private func navigateTab(direction: Int) {
        let tabs = MainTab.allCases
        guard let currentIndex = tabs.firstIndex(of: selectedTab) else { return }
        
        let newIndex = (currentIndex + direction + tabs.count) % tabs.count
        selectedTab = tabs[newIndex]
    }
}

// MARK: - Preview

struct TabBarView_Previews: PreviewProvider {
    @State static var selectedTab: MainTab = .quickStart
    
    static var previews: some View {
        TabBarView(selectedTab: $selectedTab)
            .frame(width: 400)
    }
}