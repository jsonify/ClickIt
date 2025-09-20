//
//  TabbedMainView.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

// MARK: - MainTab Enum

enum MainTab: String, CaseIterable, Identifiable {
    case quickStart = "quickStart"
    case presets = "presets"
    case settings = "settings"
    case statistics = "statistics"
    case advanced = "advanced"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .quickStart:
            return "Quick Start"
        case .presets:
            return "Presets"
        case .settings:
            return "Settings"
        case .statistics:
            return "Statistics"
        case .advanced:
            return "Advanced"
        }
    }
    
    var icon: String {
        switch self {
        case .quickStart:
            return "play.circle"
        case .presets:
            return "folder"
        case .settings:
            return "gearshape"
        case .statistics:
            return "chart.bar"
        case .advanced:
            return "wrench.and.screwdriver"
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .quickStart:
            return "Quick Start Tab - Essential clicking controls"
        case .presets:
            return "Presets Tab - Manage saved configurations"
        case .settings:
            return "Settings Tab - Configure advanced options"
        case .statistics:
            return "Statistics Tab - View performance metrics"
        case .advanced:
            return "Advanced Tab - Developer tools and diagnostics"
        }
    }
}

// MARK: - TabbedMainView

struct TabbedMainView: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @AppStorage("selectedTab") private var selectedTab: MainTab = .quickStart
    @State private var contentHeight: CGFloat = 400
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            TabBarView(selectedTab: $selectedTab)
            
            // Content Area
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        tabContent
                    }
                    .padding(16)
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear
                                .onAppear {
                                    updateContentHeight(contentGeometry.size.height)
                                }
                                .onChange(of: selectedTab) { _, _ in
                                    // Update height when tab changes
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        updateContentHeight(contentGeometry.size.height)
                                    }
                                }
                        }
                    )
                }
                .frame(height: min(max(contentHeight + 32, 400), 600)) // Min 400px, Max 600px
            }
            .frame(height: min(max(contentHeight + 32, 400), 600))
        }
        .frame(width: 400)
        .background(Color(NSColor.controlBackgroundColor))
        .animation(.easeInOut(duration: 0.3), value: contentHeight)
    }
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .quickStart:
            QuickStartTab()
        case .presets:
            PresetsTab()
        case .settings:
            SettingsTab()
        case .statistics:
            StatisticsTab()
        case .advanced:
            AdvancedTab()
        }
    }
    
    private func updateContentHeight(_ height: CGFloat) {
        let newHeight = height
        if abs(contentHeight - newHeight) > 10 { // Only update if significant change
            contentHeight = newHeight
        }
    }
}

// MARK: - Tab Views
// All tab views are now implemented in their respective files:
// - QuickStartTab.swift
// - PresetsTab.swift  
// - SettingsTab.swift
// - StatisticsTab.swift
// - AdvancedTab.swift

// MARK: - Preview

struct TabbedMainView_Previews: PreviewProvider {
    static var previews: some View {
        TabbedMainView()
            .environmentObject(ClickItViewModel())
            .frame(width: 400, height: 600)
    }
}