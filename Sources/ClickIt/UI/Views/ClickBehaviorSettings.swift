//
//  ClickBehaviorSettings.swift
//  ClickIt
//
//  Created by Jefry on 12 / 07 / 25.
//

import SwiftUI

struct ClickBehaviorSettings: View {
    @ObservedObject
    var viewModel: ClickItViewModel

    var body: some View {
        VStack(spacing: 20) {
            SettingCard(
                title: "Click Type",
                description: "Choose which mouse button to simulate during automation."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(ClickType.allCases, id: \.self) { type in
                        Button(action: {
                            viewModel.clickType = type
                        }) {
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: type.icon)
                                    .font(.title2)
                                    .frame(width: 25, alignment: .center)
                                    .foregroundColor(viewModel.clickType == type ? .accentColor : .secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.rawValue.capitalized)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    Text(type.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()

                                if viewModel.clickType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.accentColor)
                                } else {
                                    Image(systemName: "circle")
                                        .font(.title2)
                                        .foregroundColor(Color(NSColor.separatorColor))
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(viewModel.clickType == type ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            SettingCard(
                title: "Location Randomization",
                description: "Add variance to click coordinates to simulate more natural clicking patterns"
            ) {
                VStack(spacing: 12) {
                    Toggle("Randomize Click Location", isOn: $viewModel.randomizeLocation)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if viewModel.randomizeLocation {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Variance Range")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(Int(viewModel.locationVariance))px radius")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }

                            Slider(
                                value: $viewModel.locationVariance,
                                in: 0 ... 50,
                                step: 1
                            ) {
                                Text("Variance")
                            } minimumValueLabel: {
                                Text("0")
                                    .font(.caption2)
                            } maximumValueLabel: {
                                Text("50")
                                    .font(.caption2)
                            }

                            Text("Clicks will be randomly distributed within a \(Int(viewModel.locationVariance))px radius of the target point")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        .padding(.leading, 16)
                    }
                }
            }
        }
    }
}
