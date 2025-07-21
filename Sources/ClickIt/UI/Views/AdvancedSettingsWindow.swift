//
//  AdvancedSettingsWindow.swift
//  ClickIt
//
//  Created by Jefry on 12 / 07 / 25.
//

import SwiftUI

struct AdvancedSettingsWindow: View {
    @ObservedObject var viewModel: ClickItViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: SettingsSection = .clickBehavior

    var body: some View {
        NavigationSplitView {
            settingsSidebar
        } detail: {
            settingsDetail
        }
        .frame(width: 800, height: 600)
        .navigationTitle("Advanced Settings")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button("Reset All") {
                    resetAllSettings()
                }
                .foregroundColor(.red)
            }
        }
    }

    private var settingsSidebar: some View {
        List(SettingsSection.allCases, id: \.self, selection: $selectedSection) { section in
            NavigationLink(value: section) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.title)
                            .font(.headline)
                        Text(section.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: section.icon)
                        .foregroundColor(section.color)
                }
            }
        }
        .navigationTitle("Settings")
        .frame(minWidth: 250)
    }

    private var settingsDetail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: selectedSection.icon)
                            .font(.title2)
                            .foregroundColor(selectedSection.color)

                        Text(selectedSection.title)
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Text(selectedSection.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)

                switch selectedSection {
                case .clickBehavior:
                    ClickBehaviorSettings(viewModel: viewModel)
                case .timing:
                    TimingSettings(viewModel: viewModel)
                case .targeting:
                    TargetingSettings(viewModel: viewModel)
                case .feedback:
                    FeedbackSettings(viewModel: viewModel)
                case .automation:
                    AutomationSettings(viewModel: viewModel)
                case .advanced:
                    AdvancedTechnicalSettings(viewModel: viewModel)
                }

                Spacer()
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Helper Methods

    private func resetAllSettings() {
        viewModel.resetConfiguration()
    }
}

struct AdvancedSettingsWindow_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSettingsWindow(viewModel: ClickItViewModel())
    }
}
