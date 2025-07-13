//
//  FeedbackSettings.swift
//  ClickIt
//
//  Created by Jefry on 12 / 07 / 25.
//

import SwiftUI

struct FeedbackSettings: View {
    @ObservedObject
    var viewModel: ClickItViewModel

    var body: some View {
        VStack(spacing: 20) {
            SettingCard(
                title: "Visual Feedback",
                description: "Configure visual indicators during automation"
            ) {
                VStack(spacing: 12) {
                    Toggle("Show Visual Feedback", isOn: $viewModel.showVisualFeedback)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if viewModel.showVisualFeedback {
                        Text("Visual indicators will appear at click locations during automation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                    }
                }
            }

            SettingCard(
                title: "Audio Feedback",
                description: "Configure sound notifications during automation"
            ) {
                VStack(spacing: 12) {
                    Toggle("Play Sound Feedback", isOn: $viewModel.playSoundFeedback)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if viewModel.playSoundFeedback {
                        Text("Sound will play for each click during automation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }
}
