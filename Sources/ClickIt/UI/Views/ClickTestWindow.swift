//
//  ClickTestWindow.swift
//  ClickIt
//
//  Click testing window for validating auto-clicker functionality
//

import SwiftUI

/// Test window for validating click automation functionality
struct ClickTestWindow: View {
    @Environment(\.dismiss) private var dismiss
    @State private var clickCounts: [String: Int] = [:]
    @State private var lastClickTime: Date?
    @State private var lastClickPosition: CGPoint?
    @State private var totalClicks: Int = 0
    @State private var showClickIndicator: Bool = false
    @State private var indicatorPosition: CGPoint = .zero

    // Target zones
    private let targets = [
        ClickTarget(id: "top-left", name: "Top Left", color: .blue, position: .topLeft),
        ClickTarget(id: "top-right", name: "Top Right", color: .green, position: .topRight),
        ClickTarget(id: "center", name: "Center", color: .purple, position: .center),
        ClickTarget(id: "bottom-left", name: "Bottom Left", color: .orange, position: .bottomLeft),
        ClickTarget(id: "bottom-right", name: "Bottom Right", color: .red, position: .bottomRight)
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with instructions
                headerSection

                Divider()

                // Main click testing area
                ZStack {
                    // Background
                    Color(NSColor.controlBackgroundColor)

                    // Target zones - use VStack/HStack layout instead of absolute positioning
                    VStack(spacing: 40) {
                        // Top row
                        HStack(spacing: 80) {
                            targetView(for: targets[0]) // Top Left
                            Spacer()
                            targetView(for: targets[1]) // Top Right
                        }

                        Spacer()

                        // Center row
                        HStack {
                            Spacer()
                            targetView(for: targets[2]) // Center
                            Spacer()
                        }

                        Spacer()

                        // Bottom row
                        HStack(spacing: 80) {
                            targetView(for: targets[3]) // Bottom Left
                            Spacer()
                            targetView(for: targets[4]) // Bottom Right
                        }
                    }
                    .padding(60)

                    // Click indicator overlay
                    if showClickIndicator {
                        Circle()
                            .fill(Color.yellow.opacity(0.5))
                            .frame(width: 30, height: 30)
                            .position(indicatorPosition)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(minHeight: 600)

                Divider()

                // Statistics panel
                statisticsPanel
            }
            .navigationTitle("Click Test Window")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        resetCounters()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 1000, minHeight: 800)
        .frame(idealWidth: 1200, idealHeight: 900)
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)

                Text("Click Test Window")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: 6) {
                instructionRow(icon: "1.circle.fill", text: "Position your auto-clicker over any colored target zone")
                instructionRow(icon: "2.circle.fill", text: "Start the auto-clicker from the main window")
                instructionRow(icon: "3.circle.fill", text: "Watch the click counters update in real-time")
                instructionRow(icon: "scope", text: "For Active Target Mode: Enable it in main window, then click on targets")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }

    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.accentColor)
            Text(text)
        }
    }

    private func targetView(for target: ClickTarget) -> some View {
        let size: CGFloat = 150

        return VStack(spacing: 8) {
            // Click counter
            Text("\(clickCounts[target.id] ?? 0)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            // Target name
            Text(target.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(target.color.opacity(0.85))
                .shadow(color: target.color.opacity(0.4), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.4), lineWidth: 3)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            handleClick(on: target.id)
        }
    }

    private var statisticsPanel: some View {
        HStack(spacing: 20) {
            // Total clicks
            statisticView(
                title: "Total Clicks",
                value: "\(totalClicks)",
                icon: "hand.tap",
                color: .blue
            )

            Divider()

            // Last click time
            statisticView(
                title: "Last Click",
                value: lastClickTimeString,
                icon: "clock",
                color: .green
            )

            Divider()

            // Most clicked target
            statisticView(
                title: "Most Clicked",
                value: mostClickedTarget,
                icon: "star",
                color: .orange
            )

            Spacer()

            // Visual feedback indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(showClickIndicator ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)

                Text("Click Detection")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func statisticView(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Helper Methods

    private func handleClick(on targetId: String) {
        // Update click count
        clickCounts[targetId, default: 0] += 1
        totalClicks += 1
        lastClickTime = Date()

        // Show visual feedback
        withAnimation(.easeOut(duration: 0.3)) {
            showClickIndicator = true
        }

        // Hide indicator after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showClickIndicator = false
            }
        }

        // Provide haptic feedback if available
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .now
        )

        print("ClickTestWindow: Click detected on \(targetId), total: \(totalClicks)")
    }

    private func resetCounters() {
        clickCounts.removeAll()
        totalClicks = 0
        lastClickTime = nil
        lastClickPosition = nil
        print("ClickTestWindow: Counters reset")
    }

    private var lastClickTimeString: String {
        guard let time = lastClickTime else {
            return "None"
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: time)
    }

    private var mostClickedTarget: String {
        guard let maxTarget = clickCounts.max(by: { $0.value < $1.value }) else {
            return "None"
        }

        if let target = targets.first(where: { $0.id == maxTarget.key }) {
            return "\(target.name) (\(maxTarget.value))"
        }

        return "None"
    }
}

// MARK: - Supporting Types

struct ClickTarget: Identifiable {
    let id: String
    let name: String
    let color: Color
    let position: TargetPosition
}

enum TargetPosition {
    case topLeft, topRight, center, bottomLeft, bottomRight
}

// MARK: - Preview

struct ClickTestWindow_Previews: PreviewProvider {
    static var previews: some View {
        ClickTestWindow()
    }
}
