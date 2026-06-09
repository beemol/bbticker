//
//  BybitWidgetLockScreenViews.swift
//  BybitWidget
//

import SwiftUI
import WidgetKit

// MARK: - Helper Functions

private func formatCompact(_ value: String) -> String {
    guard let doubleValue = Double(value) else { return value }
    
    if doubleValue >= 1_000_000 {
        return String(format: "%.1fM", doubleValue / 1_000_000)
    } else if doubleValue >= 1_000 {
        return String(format: "%.1fK", doubleValue / 1_000)
    } else {
        return String(format: "%.0f", doubleValue)
    }
}

private func formatTimeAgo(_ date: Date) -> String {
    let seconds = Int(Date().timeIntervalSince(date))
    if seconds < 60 { return "\(seconds)s" }
    let minutes = seconds / 60
    if minutes < 60 { return "\(minutes)m" }
    let hours = minutes / 60
    return "\(hours)h"
}

// MARK: - Circular Lock Screen Widget (Small Circle)

struct BybitCircularLockScreenView: View {
    let entry: BybitWidgetEntry
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: entry.connectionStatus == "Connected" ? "dollarsign.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(entry.connectionStatus == "Connected" ? .green : .red)
            
            Text(formatCompact(entry.totalEquity))
                .font(.system(size: 13, weight: .bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

// MARK: - Rectangular Lock Screen Widget (Wide Rectangle)

struct BybitRectangularLockScreenView: View {
    let entry: BybitWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 11))
                Text("Balance")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.secondary)
            
            Text("$\(entry.totalEquity)")
                .font(.system(size: 18, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            HStack(spacing: 4) {
                Circle()
                    .fill(entry.connectionStatus == "Connected" ? Color.green : Color.red)
                    .frame(width: 5, height: 5)
                Text(formatTimeAgo(entry.lastUpdate))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

// MARK: - Inline Lock Screen Widget (Text in Notification Area)

struct BybitInlineLockScreenView: View {
    let entry: BybitWidgetEntry
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: entry.connectionStatus == "Connected" ? "dollarsign.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(entry.connectionStatus == "Connected" ? .green : .red)
            Text("$\(formatCompact(entry.totalEquity))")
                .font(.system(size: 13, weight: .semibold))
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

// MARK: - Previews

struct BybitLockScreenWidgets_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Circular widget preview
            BybitCircularLockScreenView(entry: BybitWidgetEntry(
                date: Date(),
                totalEquity: "12345.67",
                walletBalance: "9876.54",
                connectionStatus: "Connected",
                lastUpdate: Date()
            ))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular - Connected")
            
            BybitCircularLockScreenView(entry: BybitWidgetEntry(
                date: Date(),
                totalEquity: "0.00",
                walletBalance: "0.00",
                connectionStatus: "Disconnected",
                lastUpdate: Date()
            ))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular - Disconnected")
            
            // Rectangular widget preview
            BybitRectangularLockScreenView(entry: BybitWidgetEntry(
                date: Date(),
                totalEquity: "12345.67",
                walletBalance: "9876.54",
                connectionStatus: "Connected",
                lastUpdate: Date()
            ))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Rectangular - Connected")
            
            BybitRectangularLockScreenView(entry: BybitWidgetEntry(
                date: Date(),
                totalEquity: "0.00",
                walletBalance: "0.00",
                connectionStatus: "Disconnected",
                lastUpdate: Date().addingTimeInterval(-300)
            ))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Rectangular - Disconnected")
            
            // Inline widget preview
            BybitInlineLockScreenView(entry: BybitWidgetEntry(
                date: Date(),
                totalEquity: "12345.67",
                walletBalance: "9876.54",
                connectionStatus: "Connected",
                lastUpdate: Date()
            ))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            .previewDisplayName("Inline - Connected")
            
            BybitInlineLockScreenView(entry: BybitWidgetEntry(
                date: Date(),
                totalEquity: "0.00",
                walletBalance: "0.00",
                connectionStatus: "Disconnected",
                lastUpdate: Date()
            ))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            .previewDisplayName("Inline - Disconnected")
        }
    }
}

