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
        // Get main screen bounds
        let screenFrame = NSScreen.main?.frame ?? CGRect.zero
        
        // Check if point is within screen bounds
        if point.x < 0 || point.x > screenFrame.width || 
           point.y < 0 || point.y > screenFrame.height {
            let maxX = Int(screenFrame.width)
            let maxY = Int(screenFrame.height)
            validationError = "Coordinates must be within screen bounds (0,0) to (\(maxX),\(maxY))"
            return false
        }
        
        return true
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
            let screenPoint = NSEvent.mouseLocation
            
            // NSEvent.mouseLocation already gives us the correct coordinates
            // No conversion needed - use them directly
            let convertedPoint = CGPoint(
                x: screenPoint.x,
                y: screenPoint.y
            )
            
            print("ClickCoordinateCapture: Raw mouse location: \(screenPoint)")
            print("ClickCoordinateCapture: Converted point: \(convertedPoint)")
            
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
}

#Preview {
    ClickPointSelector { point in
        print("Selected point: \(point)")
    }
    .frame(width: 400, height: 500)
}
