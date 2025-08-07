//
//  CompactTargetSelector.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

struct CompactTargetSelector: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @State private var isCapturingMouse = false
    @State private var showingMouseCapture = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                
                Text("Target Location")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let point = viewModel.targetPoint {
                    Text("(\(Int(point.x)), \(Int(point.y)))")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 8) {
                // Capture Button
                Button(action: {
                    showingMouseCapture = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isCapturingMouse ? "dot.circle.and.hand.point.up.left.fill" : "hand.point.up.left")
                            .font(.system(size: 12))
                        
                        Text(isCapturingMouse ? "Capturing..." : "Capture")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(.bordered)
                .disabled(isCapturingMouse || viewModel.isRunning)
                
                // Current Position Display
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.targetPoint != nil ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    
                    Text(viewModel.targetPoint != nil ? "Set" : "Not Set")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.targetPoint != nil ? .green : .orange)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .sheet(isPresented: $showingMouseCapture) {
            MouseCaptureSheet(
                isCapturing: $isCapturingMouse,
                onPointCaptured: { point in
                    viewModel.setTargetPoint(point)
                    showingMouseCapture = false
                    isCapturingMouse = false
                }
            )
        }
    }
}

// Simple mouse capture sheet for target selection
private struct MouseCaptureSheet: View {
    @Binding var isCapturing: Bool
    let onPointCaptured: (CGPoint) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Click to Set Target")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Move your mouse to the desired location and click to set the target point.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Use Current Position") {
                    let currentPosition = NSEvent.mouseLocation
                    let cgPosition = CoordinateUtils.convertAppKitToCoreGraphics(currentPosition)
                    onPointCaptured(cgPosition)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 300)
        .onAppear {
            isCapturing = true
        }
        .onDisappear {
            isCapturing = false
        }
    }
}

// MARK: - Preview

struct CompactTargetSelector_Previews: PreviewProvider {
    static var previews: some View {
        CompactTargetSelector()
            .environmentObject(ClickItViewModel())
            .frame(width: 400)
            .padding()
    }
}