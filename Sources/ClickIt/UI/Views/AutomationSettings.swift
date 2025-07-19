//
//  AutomationSettings.swift
//  ClickIt
//
//  Created by Jefry on 12 / 07 / 25.
//

import SwiftUI

struct AutomationSettings: View {
    @ObservedObject
    var viewModel: ClickItViewModel

    var body: some View {
        VStack(spacing: 20) {
            SettingCard(
                title: "Error Handling",
                description: "Configure how ClickIt responds to errors during automation"
            ) {
                VStack(spacing: 12) {
                    Toggle("Stop on Error", isOn: $viewModel.stopOnError)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(viewModel.stopOnError
                        ? "Automation will stop if any errors occur"
                        : "Automation will continue even if errors occur")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 16)
                }
            }

            SettingCard(
                title: "Hotkey Configuration",
                description: "Global hotkey settings for automation control"
            ) {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "keyboard")
                            .foregroundColor(.blue)
                        Text("DELETE Key")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Start/Stop Automation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("Press DELETE at any time to start or stop automation, even when ClickIt is not the active application")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
