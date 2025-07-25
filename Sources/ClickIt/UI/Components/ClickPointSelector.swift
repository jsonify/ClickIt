// swiftlint:disable file_header
import SwiftUI
import CoreGraphics

struct ClickPointSelector: View {
    @State private var selectedPoint: CGPoint?
    @State private var isSelecting = false
    @State private var manualX: String = ""
    @State private var manualY: String = ""
    @State private var showingManualInput = false
    @State private var validationError: String?
    
    let onPointSelected: (CGPoint) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                Text("Click Point Selection")
                    .font(.headline)
                Spacer()
            }
            
            // Current selection display
            if let point = selectedPoint {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Selected Point:")
                        .font(.subheadline)
                    Spacer()
                    Text("X: \(Int(point.x)), Y: \(Int(point.y))")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Selection methods
            HStack(spacing: 12) {
                // Click to set button
                Button(action: startClickSelection) {
                    HStack {
                        Image(systemName: isSelecting ? "stop.circle.fill" : "hand.tap.fill")
                        Text(isSelecting ? "Cancel" : "Click to Set Point")
                    }
                    .foregroundColor(isSelecting ? .red : .blue)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(isSelecting)
                
                // Manual input toggle
                Button(action: { showingManualInput.toggle() }) {
                    HStack {
                        Image(systemName: "keyboard")
                        Text("Manual Input")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            
            // Manual input section
            if showingManualInput {
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text("X:")
                                .font(.caption)
                            TextField("X", text: $manualX)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Y:")
                                .font(.caption)
                            TextField("Y", text: $manualY)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Button("Set Point") {
                            setManualPoint()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(manualX.isEmpty || manualY.isEmpty)
                    }
                }
                .padding(10)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Validation error
            if let error = validationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Instructions
            VStack(alignment: .leading, spacing: 2) {
                Text("Instructions:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("• Click 'Click to Set Point' then click anywhere on screen")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("• Or use manual input for precise coordinates")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func startClickSelection() {
        isSelecting = true
        clearValidationError()
        
        // Start global mouse click monitoring
        Task { @MainActor in
            ClickCoordinateCapture.captureNextClick { point in
                self.handleCapturedPoint(point)
            }
        }
    }
    
    private func handleCapturedPoint(_ point: CGPoint) {
        isSelecting = false
        
        if validateCoordinates(point) {
            selectedPoint = point
            onPointSelected(point)
        }
    }
    
    private func setManualPoint() {
        clearValidationError()
        
        guard let x = Double(manualX), let y = Double(manualY) else {
            validationError = "Invalid coordinates. Please enter valid numbers."
            return
        }
        
        let point = CGPoint(x: x, y: y)
        
        if validateCoordinates(point) {
            selectedPoint = point
            onPointSelected(point)
        }
    }
    
    private func validateCoordinates(_ point: CGPoint) -> Bool {
        // FIXED: Check all screens, not just main screen
        print("🔍 [ClickPointSelector] Validating coordinates: \(point)")
        
        for (index, screen) in NSScreen.screens.enumerated() {
            if screen.frame.contains(point) {
                print("✅ [ClickPointSelector] Point is valid on screen \(index): \(screen.frame)")
                return true
            }
            print("   Screen \(index): \(screen.frame) - contains: false")
        }
        
        // If not found on any screen, show error with all screen bounds
        let allScreens = NSScreen.screens.enumerated().map { "Screen \($0): \($1.frame)" }.joined(separator: ", ")
        validationError = "Coordinates (\(Int(point.x)),\(Int(point.y))) are not within any screen bounds. Available screens: \(allScreens)"
        print("❌ [ClickPointSelector] Validation failed: \(validationError ?? "unknown error")")
        return false
    }
    
    private func clearValidationError() {
        validationError = nil
    }
}

// MARK: - Click Coordinate Capture
struct ClickCoordinateCapture {
    @MainActor
    static func captureNextClick(completion: @escaping @MainActor (CGPoint) -> Void) {
        // Create global event monitor for left mouse clicks
        var eventMonitor: Any?
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { _ in
            let appKitPoint = NSEvent.mouseLocation
            print("ClickCoordinateCapture: Raw mouse location (AppKit): \(appKitPoint)")
            
            // FIXED: Convert AppKit coordinates to CoreGraphics coordinates for multi-monitor setups
            let convertedPoint = convertAppKitToCoreGraphics(appKitPoint)
            print("ClickCoordinateCapture: Converted to CoreGraphics: \(convertedPoint)")
            
            // Clean up monitor
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }
            
            // Call completion on main thread
            Task { @MainActor in
                completion(convertedPoint)
            }
        }
    }
    
    /// Converts AppKit coordinates to CoreGraphics coordinates for multi-monitor setups
    private static func convertAppKitToCoreGraphics(_ appKitPosition: CGPoint) -> CGPoint {
        // Find which screen contains this point
        for screen in NSScreen.screens {
            if screen.frame.contains(appKitPosition) {
                // FIXED: Proper multi-monitor coordinate conversion
                // AppKit Y increases upward from screen bottom
                // CoreGraphics Y increases downward from screen top  
                // Formula: CG_Y = screen.origin.Y + (screen.height - (AppKit_Y - screen.origin.Y))
                let relativeY = appKitPosition.y - screen.frame.origin.y  // Y relative to screen bottom
                let cgY = screen.frame.origin.y + (screen.frame.height - relativeY)  // Convert to CG coordinates
                let cgPosition = CGPoint(x: appKitPosition.x, y: cgY)
                print("ClickCoordinateCapture: Multi-monitor conversion on screen \(screen.frame)")
                print("ClickCoordinateCapture: Calculation: relativeY=\(relativeY), cgY=\(screen.frame.origin.y) + (\(screen.frame.height) - \(relativeY)) = \(cgY)")
                return cgPosition
            }
        }
        
        // Fallback to main screen if no screen contains the point
        let mainScreenHeight = NSScreen.main?.frame.height ?? 0
        let fallbackPosition = CGPoint(x: appKitPosition.x, y: mainScreenHeight - appKitPosition.y)
        print("ClickCoordinateCapture: Fallback conversion: AppKit \(appKitPosition) → CoreGraphics \(fallbackPosition)")
        return fallbackPosition
    }
}

struct ClickPointSelector_Previews: PreviewProvider {
    static var previews: some View {
        ClickPointSelector { point in
            print("Selected point: \(point)")
        }
        .frame(width: 400, height: 500)
    }
}
