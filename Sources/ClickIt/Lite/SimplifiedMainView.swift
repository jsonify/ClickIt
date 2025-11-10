//
//  SimplifiedMainView.swift
//  ClickIt Lite
//
//  Single-window simplified UI for ClickIt Lite.
//

import SwiftUI

struct SimplifiedMainView: View {

    // MARK: - Properties

    @StateObject private var viewModel = SimpleViewModel()
    @StateObject private var permissionManager = SimplePermissionManager.shared

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("ClickIt Lite")
                .font(.title)
                .fontWeight(.bold)

            Divider()

            // Permission check
            if !permissionManager.hasAccessibilityPermission {
                permissionSection
            }

            // Click Location
            clickLocationSection

            // Click Interval
            clickIntervalSection

            // Click Type
            clickTypeSection

            Spacer()

            // Start/Stop Button
            startStopButton

            // Status
            statusSection

            Spacer()
        }
        .padding(30)
        .frame(width: 400, height: 550)
        .onAppear {
            permissionManager.checkPermissions()
        }
    }

    // MARK: - View Components

    private var permissionSection: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Accessibility Permission Required")
                    .font(.headline)
            }

            Button("Grant Permission") {
                permissionManager.requestAccessibilityPermission()
            }
            .buttonStyle(.borderedProminent)

            Text("Click to open System Settings and grant permission")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    private var clickLocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Click Location")
                .font(.headline)

            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("X: \(Int(viewModel.clickLocation.x))")
                        .font(.system(.body, design: .monospaced))
                    Text("Y: \(Int(viewModel.clickLocation.y))")
                        .font(.system(.body, design: .monospaced))
                }
                .frame(width: 100, alignment: .leading)

                Button("Set from Mouse") {
                    viewModel.setClickLocationFromMouse()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            Text("Click 'Set from Mouse' to capture current mouse position")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var clickIntervalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Click Interval")
                    .font(.headline)
                Spacer()
                Text("\(String(format: "%.1f", viewModel.clickInterval))s")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.blue)
            }

            Slider(value: $viewModel.clickInterval, in: 0.1...10.0, step: 0.1)
                .disabled(viewModel.isRunning)

            HStack {
                Text("0.1s")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("10s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var clickTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Click Type")
                .font(.headline)

            Picker("", selection: $viewModel.clickType) {
                Text("Left Click").tag(SimpleClickEngine.ClickType.left)
                Text("Right Click").tag(SimpleClickEngine.ClickType.right)
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isRunning)
        }
    }

    private var startStopButton: some View {
        Button(action: {
            if viewModel.isRunning {
                viewModel.stopClicking()
            } else {
                viewModel.startClicking()
            }
        }) {
            Text(viewModel.isRunning ? "STOP CLICKING" : "START CLICKING")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isRunning ? Color.red : Color.green)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .disabled(!permissionManager.hasAccessibilityPermission)
    }

    private var statusSection: some View {
        VStack(spacing: 4) {
            Text(viewModel.statusMessage)
                .font(.body)
                .fontWeight(.medium)

            if !viewModel.isRunning {
                Text("Press ESC anytime to stop")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Press ESC to emergency stop")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SimplifiedMainView()
}
