import SwiftUI

struct SchedulingCard: View {
    @ObservedObject var viewModel: ClickItViewModel
    @StateObject private var schedulingManager = SchedulingManager.shared

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.purple)
                    .font(.system(size: 16))

                Text("Scheduling")
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                // Quick indicator if scheduling is active
                if schedulingManager.hasScheduledTask {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.purple)
                        .font(.system(size: 12))
                }
            }

            // Scheduling Mode Selection
            VStack(spacing: 12) {
                HStack {
                    Text("Execution Mode:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()
                }

                Picker("Scheduling Mode", selection: $viewModel.clickSettings.schedulingMode) {
                    ForEach(SchedulingMode.allCases, id: \.self) { mode in
                        Text(mode.displayName)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Scheduled Time Section (only show if scheduled mode is selected)
            if viewModel.clickSettings.schedulingMode == .scheduled {
                VStack(spacing: 12) {
                    HStack {
                        Text("Scheduled Time:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()
                    }

                    DatePicker(
                        "Schedule Date & Time",
                        selection: $viewModel.clickSettings.scheduledDateTime,
                        in: Date()...,  // Only allow future dates
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }

                // Validation Message for Scheduled Time
                if !viewModel.clickSettings.isScheduledTimeValid {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        Text("Scheduled time must be in the future")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }

            // Scheduling Status Display
            if schedulingManager.hasScheduledTask {
                VStack(spacing: 8) {
                    HStack {
                        Text("Status:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        Text("Scheduled")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                    }

                    HStack {
                        Text("Starts:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        Text(schedulingManager.countdownString)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.purple)
                            .fontWeight(.semibold)
                    }

                    // Scheduled time display
                    HStack {
                        Text("At:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(formatScheduledTime(schedulingManager.scheduledDateTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
            }

            // Information about scheduling mode
            if viewModel.clickSettings.schedulingMode == .scheduled {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.system(size: 12))
                    Text("Automation will begin at the scheduled time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func formatScheduledTime(_ date: Date?) -> String {
        guard let date = date else { return "Not set" }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        return formatter.string(from: date)
    }
}

#Preview {
    SchedulingCard(viewModel: {
        let vm = ClickItViewModel()
        vm.clickSettings.schedulingMode = .scheduled
        vm.clickSettings.scheduledDateTime = Date().addingTimeInterval(3600) // 1 hour from now
        return vm
    }())
    .frame(width: 400)
    .padding()
}