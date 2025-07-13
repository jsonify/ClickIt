import SwiftUI

struct ConfigurationPanelCard: View {
    @ObservedObject var viewModel: ClickItViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Text("Click Interval")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            // Time Input Fields
            VStack(spacing: 16) {
                // Time inputs row
                HStack(spacing: 12) {
                    TimeInputField(
                        label: "Hours",
                        value: $viewModel.intervalHours,
                        range: 0...23
                    )
                    
                    TimeInputField(
                        label: "Mins",
                        value: $viewModel.intervalMinutes,
                        range: 0...59
                    )
                    
                    TimeInputField(
                        label: "Secs",
                        value: $viewModel.intervalSeconds,
                        range: 0...59
                    )
                    
                    TimeInputField(
                        label: "Ms",
                        value: $viewModel.intervalMilliseconds,
                        range: 0...999
                    )
                }
                
                // Total time and CPS display
                VStack(spacing: 8) {
                    HStack {
                        Text("Total:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(formatTotalTime(viewModel.totalMilliseconds))
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("CPS:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(String(format: "~%.2f CPS", viewModel.estimatedCPS))
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                }
                .padding(12)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Input validation
            if viewModel.totalMilliseconds <= 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    Text("Click interval must be greater than 0")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func formatTotalTime(_ milliseconds: Int) -> String {
        if milliseconds < 1000 {
            return "\(milliseconds)ms"
        } else if milliseconds < 60000 {
            let seconds = Double(milliseconds) / 1000.0
            return String(format: "%.1fs", seconds)
        } else {
            let totalSeconds = milliseconds / 1000
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            let ms = milliseconds % 1000
            
            if ms > 0 {
                return "\(minutes)m \(seconds)s \(ms)ms"
            } else if seconds > 0 {
                return "\(minutes)m \(seconds)s"
            } else {
                return "\(minutes)m"
            }
        }
    }
}

struct TimeInputField: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    @FocusState private var isFocused: Bool
    @State private var textValue: String = ""
    
    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            TextField("0", text: $textValue)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .focused($isFocused)
                .onChange(of: textValue) { _, newValue in
                    updateValueFromText(newValue)
                }
                .onChange(of: value) { _, newValue in
                    if !isFocused {
                        textValue = String(newValue)
                    }
                }
                .onAppear {
                    textValue = String(value)
                }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func updateValueFromText(_ text: String) {
        // Allow empty text while editing
        if text.isEmpty && isFocused {
            return
        }
        
        // Parse and validate the number
        if let number = Int(text), range.contains(number) {
            value = number
        } else if !text.isEmpty {
            // Invalid input - revert to current value
            textValue = String(value)
        } else {
            // Empty input when not focused - set to 0 if in range
            value = range.contains(0) ? 0 : range.lowerBound
            textValue = String(value)
        }
    }
}

#Preview {
    ConfigurationPanelCard(viewModel: {
        let vm = ClickItViewModel()
        vm.intervalSeconds = 1
        vm.intervalMilliseconds = 500
        return vm
    }())
    .frame(width: 400)
    .padding()
}