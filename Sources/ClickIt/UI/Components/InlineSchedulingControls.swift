//
//  InlineSchedulingControls.swift
//  ClickIt
//
//  Created by ClickIt on 2025-10-09.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

struct InlineSchedulingControls: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @StateObject private var schedulingManager = SchedulingManager.shared
    @State private var isExpanded = false

    // Time input fields
    @State private var hourText = "00"
    @State private var minuteText = "00"
    @State private var secondText = "00"
    @State private var isUpdatingFromCode = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 12) {
                // Scheduling Mode Selection
                Picker("Execution Mode", selection: $viewModel.clickSettings.schedulingMode) {
                    ForEach(SchedulingMode.allCases, id: \.self) { mode in
                        Text(mode.displayName)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                // Scheduled Time Section (only show if scheduled mode is selected)
                if viewModel.clickSettings.schedulingMode == .scheduled {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Scheduled Time:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            Spacer()
                        }

                        // Date Picker
                        DatePicker(
                            "Date",
                            selection: $viewModel.clickSettings.scheduledDateTime,
                            in: Date()...,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .onChange(of: viewModel.clickSettings.scheduledDateTime) {
                            if !isUpdatingFromCode {
                                updateFieldsFromDateTime()
                            }
                        }

                        // Time Input Fields
                        HStack(spacing: 4) {
                            Text("Time:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            // Hour Field
                            TextField("00", text: $hourText)
                                .font(.system(.body, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .frame(width: 35)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(6)
                                .onChange(of: hourText) {
                                    validateAndUpdateHour()
                                    updateTimeFromFieldsNoPad()
                                }
                                .onSubmit {
                                    padTimeFields()
                                    updateTimeFromFieldsNoPad()
                                }

                            Text(":")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)

                            // Minute Field
                            TextField("00", text: $minuteText)
                                .font(.system(.body, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .frame(width: 35)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(6)
                                .onChange(of: minuteText) {
                                    validateAndUpdateMinute()
                                    updateTimeFromFieldsNoPad()
                                }
                                .onSubmit {
                                    padTimeFields()
                                    updateTimeFromFieldsNoPad()
                                }

                            Text(":")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)

                            // Second Field
                            TextField("00", text: $secondText)
                                .font(.system(.body, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .frame(width: 35)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(6)
                                .onChange(of: secondText) {
                                    validateAndUpdateSecond()
                                    updateTimeFromFieldsNoPad()
                                }
                                .onSubmit {
                                    padTimeFields()
                                    updateTimeFromFieldsNoPad()
                                }
                        }
                        .onAppear {
                            updateFieldsFromDateTime()
                        }
                    }

                    // Display exact scheduled time with seconds
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))

                            Text("Will execute at:")
                                .font(.system(.caption2))
                                .foregroundColor(.secondary)

                            Spacer()
                        }

                        HStack {
                            Text(TimeZoneHelper.formatDualTime(viewModel.clickSettings.scheduledDateTime))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)

                            Spacer()
                        }
                    }

                    // Diagnostic View - Shows exact timing information
                    SchedulingDiagnosticView()
                        .environmentObject(viewModel)

                    // Validation Message for Scheduled Time
                    if !viewModel.clickSettings.isScheduledTimeValid {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .font(.system(size: 10))
                            Text("Scheduled time must be in the future")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Spacer()
                        }
                    }
                }

                // Scheduling Status Display
                if schedulingManager.hasScheduledTask {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Status:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("Scheduled")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                        }

                        HStack {
                            Text("Starts in:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(schedulingManager.countdownString)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.purple)
                                .fontWeight(.semibold)
                        }

                        // Cancel button for scheduled tasks
                        Button(action: {
                            viewModel.cancelScheduledTask()
                        }) {
                            Label("Cancel Scheduled Task", systemImage: "xmark.circle")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .controlSize(.small)
                    }
                    .padding(8)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.purple)
                    .font(.system(size: 14))

                Text("Scheduling")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                // Quick status display
                if schedulingManager.hasScheduledTask {
                    Text(schedulingManager.shortCountdownDescription)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.purple)
                        .fontWeight(.semibold)
                } else {
                    Text(viewModel.clickSettings.schedulingMode.displayName)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    // MARK: - Helper Methods

    private func updateFieldsFromDateTime() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: viewModel.clickSettings.scheduledDateTime)
        let minute = calendar.component(.minute, from: viewModel.clickSettings.scheduledDateTime)
        let second = calendar.component(.second, from: viewModel.clickSettings.scheduledDateTime)

        hourText = String(format: "%02d", hour)
        minuteText = String(format: "%02d", minute)
        secondText = String(format: "%02d", second)
    }

    private func updateTimeFromFields() {
        // Pad fields before parsing
        padTimeFields()

        // Parse the padded fields
        guard let hour = Int(hourText.isEmpty ? "0" : hourText),
              let minute = Int(minuteText.isEmpty ? "0" : minuteText),
              let second = Int(secondText.isEmpty ? "0" : secondText) else { return }

        let calendar = Calendar.current
        let now = Date()

        // Get the date component from scheduledDateTime
        var components = calendar.dateComponents([.year, .month, .day], from: viewModel.clickSettings.scheduledDateTime)
        components.hour = hour
        components.minute = minute
        components.second = second

        if let newDate = calendar.date(from: components) {
            // Set flag to prevent feedback loop
            isUpdatingFromCode = true

            // If the time is in the past, add one day (only on submit, not during typing)
            if newDate <= now {
                if let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: newDate) {
                    viewModel.clickSettings.scheduledDateTime = tomorrowDate
                } else {
                    viewModel.clickSettings.scheduledDateTime = newDate
                }
            } else {
                viewModel.clickSettings.scheduledDateTime = newDate
            }

            // Reset flag
            DispatchQueue.main.async {
                self.isUpdatingFromCode = false
            }
        }
    }

    private func updateTimeFromFieldsNoPad() {
        // Parse without padding
        guard let hour = Int(hourText.isEmpty ? "0" : hourText),
              let minute = Int(minuteText.isEmpty ? "0" : minuteText),
              let second = Int(secondText.isEmpty ? "0" : secondText) else { return }

        let calendar = Calendar.current

        // Get the date component from scheduledDateTime (preserve the selected date)
        var components = calendar.dateComponents([.year, .month, .day], from: viewModel.clickSettings.scheduledDateTime)
        components.hour = hour
        components.minute = minute
        components.second = second

        if let newDate = calendar.date(from: components) {
            // Set flag to prevent feedback loop
            isUpdatingFromCode = true

            // Don't auto-adjust to tomorrow during typing - just set the time as-is
            viewModel.clickSettings.scheduledDateTime = newDate

            // Reset flag
            DispatchQueue.main.async {
                self.isUpdatingFromCode = false
            }
        }
    }

    private func validateAndUpdateHour() {
        // Remove non-numeric characters
        hourText = hourText.filter { $0.isNumber }

        // Limit to 2 digits
        if hourText.count > 2 {
            hourText = String(hourText.prefix(2))
        }

        // Validate range
        if let hour = Int(hourText), hour > 23 {
            hourText = "23"
        }
    }

    private func validateAndUpdateMinute() {
        // Remove non-numeric characters
        minuteText = minuteText.filter { $0.isNumber }

        // Limit to 2 digits
        if minuteText.count > 2 {
            minuteText = String(minuteText.prefix(2))
        }

        // Validate range
        if let minute = Int(minuteText), minute > 59 {
            minuteText = "59"
        }
    }

    private func validateAndUpdateSecond() {
        // Remove non-numeric characters
        secondText = secondText.filter { $0.isNumber }

        // Limit to 2 digits
        if secondText.count > 2 {
            secondText = String(secondText.prefix(2))
        }

        // Validate range
        if let second = Int(secondText), second > 59 {
            secondText = "59"
        }
    }

    private func padTimeFields() {
        // Pad fields to 2 digits
        if hourText.count == 1 {
            hourText = "0" + hourText
        }
        if minuteText.count == 1 {
            minuteText = "0" + minuteText
        }
        if secondText.count == 1 {
            secondText = "0" + secondText
        }
    }
}

// MARK: - Preview

struct InlineSchedulingControls_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Immediate mode preview
            InlineSchedulingControls()
                .environmentObject({
                    let vm = ClickItViewModel()
                    return vm
                }())

            // Scheduled mode preview
            InlineSchedulingControls()
                .environmentObject({
                    let vm = ClickItViewModel()
                    return vm
                }())
        }
        .frame(width: 400)
        .padding()
    }
}