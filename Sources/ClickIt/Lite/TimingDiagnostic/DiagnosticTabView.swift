//
//  DiagnosticTabView.swift
//  ClickIt Lite
//
//  In-app diagnostic tab for the Lite scheduler.
//  Passively displays timing accuracy data recorded by LiteScheduler
//  each time a scheduled click fires.
//

import SwiftUI

struct DiagnosticTabView: View {

    // MARK: - Properties

    let session: DiagnosticSession

    // MARK: - Computed Properties

    /// Severity based on the worst (max) delta recorded this session.
    /// `nil` when no firings have been observed yet.
    var badgeSeverity: TimingRecord.Severity? {
        guard let max = session.maxDeltaMs else { return nil }
        return TimingRecord.Severity(delta: max)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            if session.totalCount == 0 {
                emptyStateView
            } else {
                statsView
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No Timing Data Yet")
                .font(.headline)
            Text("Schedule a click to see accuracy measurements.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    private var statsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Severity badge
            HStack {
                Text("Accuracy")
                    .font(.headline)
                Spacer()
                if let severity = badgeSeverity {
                    SeverityBadge(severity: severity)
                }
            }

            Divider()

            // Stats grid
            VStack(spacing: 10) {
                statRow(label: "Firings", value: "\(session.totalCount)")
                if let min = session.minDeltaMs {
                    statRow(label: "Min Delta", value: formatDelta(min))
                }
                if let max = session.maxDeltaMs {
                    statRow(label: "Max Delta", value: formatDelta(max))
                }
                if let avg = session.averageDeltaMs {
                    statRow(label: "Avg Delta", value: formatDelta(avg))
                }
            }
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }

    private func formatDelta(_ ms: Double) -> String {
        String(format: "%.1f ms", ms)
    }
}

// MARK: - SeverityBadge

private struct SeverityBadge: View {
    let severity: TimingRecord.Severity

    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch severity {
        case .green:  return "Good"
        case .yellow: return "Degraded"
        case .red:    return "Poor"
        }
    }

    private var color: Color {
        switch severity {
        case .green:  return .green
        case .yellow: return .orange
        case .red:    return .red
        }
    }
}

// MARK: - Preview

struct DiagnosticTabView_Previews: PreviewProvider {
    static var previews: some View {
        let emptySession = DiagnosticSession()
        let populatedSession = DiagnosticSession()
        let scheduled = Date(timeIntervalSinceReferenceDate: 1000.0)
        populatedSession.add(TimingRecord(scheduledAt: scheduled,
                                          actualAt: scheduled.addingTimeInterval(0.007)))
        populatedSession.add(TimingRecord(scheduledAt: scheduled,
                                          actualAt: scheduled.addingTimeInterval(0.012)))

        return Group {
            DiagnosticTabView(session: emptySession)
                .previewDisplayName("Empty State")
            DiagnosticTabView(session: populatedSession)
                .previewDisplayName("With Data")
        }
    }
}
