import WidgetKit
import SwiftUI

private func formatTimeAgo(_ date: Date) -> String {
    let now = Date()
    let timeInterval = now.timeIntervalSince(date)
    
    let hours = Int(timeInterval) / 3600
    let minutes = (Int(timeInterval) % 3600) / 60
    let seconds = Int(timeInterval) % 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m \(String(format: "%02d", seconds))s"
    } else if minutes > 0 {
        return "\(minutes)m \(String(format: "%02d", seconds))s"
    } else {
        return "\(seconds)s"
    }
}

// MARK: - Widget Background Helper
// Note: containerBackground is the modern API for widget backgrounds (iOS 17+)
// For iOS 14-16, we use the legacy .background() modifier

struct BybitWidgetView: View {
    let entry: BybitWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        // Home Screen widgets
        case .systemSmall:
            BybitWidgetSmallView(entry: entry)
        case .systemMedium:
            BybitWidgetMediumView(entry: entry)
            
        // Lock Screen widgets (iOS 16+)
        case .accessoryCircular:
            BybitCircularLockScreenView(entry: entry)
        case .accessoryRectangular:
            BybitRectangularLockScreenView(entry: entry)
        case .accessoryInline:
            BybitInlineLockScreenView(entry: entry)
            
        default:
            BybitWidgetSmallView(entry: entry)
        }
    }
}

struct BybitWidgetSmallView: View {
    let entry: BybitWidgetEntry
    
    var body: some View {
        VStack(spacing: 4) {
            Text(entry.totalEquity)
                .font(.title2)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(entry.connectionStatus)
                .font(.caption2)
                .foregroundColor(entry.connectionStatus == "Connected" ? .green : .red)
            
            Text("Updated: \(formatTimeAgo(entry.lastUpdate))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct BybitWidgetMediumView: View {
    let entry: BybitWidgetEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Total Equity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.totalEquity)
                        .font(.title)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Wallet Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(entry.walletBalance)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .padding()
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text(entry.connectionStatus)
                            .font(.caption2)
                            .foregroundColor(entry.connectionStatus == "Connected" ? .green : .red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                    }
                }
                Spacer()
            }
            .padding(.top, 8)
            .padding(.trailing, 8)
        )
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct BybitWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Home Screen widgets
            BybitWidgetView(entry: BybitWidgetEntry(
                date: Date(),
                totalEquity: "12345.67",
                walletBalance: "9876.54",
                connectionStatus: "Connected",
                lastUpdate: Date()
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Home - Small")
            
            BybitWidgetView(entry: BybitWidgetEntry(
                date: Date(),
                totalEquity: "12345.67",
                walletBalance: "9876.54",
                connectionStatus: "Connected",
                lastUpdate: Date()
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Home - Medium")
            
            // Lock Screen widgets
            BybitWidgetView(entry: BybitWidgetEntry(
                date: Date(),
                totalEquity: "12345.67",
                walletBalance: "9876.54",
                connectionStatus: "Connected",
                lastUpdate: Date()
            ))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Lock Screen - Circular")
            
            BybitWidgetView(entry: BybitWidgetEntry(
                date: Date(),
                totalEquity: "12345.67",
                walletBalance: "9876.54",
                connectionStatus: "Connected",
                lastUpdate: Date()
            ))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Lock Screen - Rectangular")
            
            BybitWidgetView(entry: BybitWidgetEntry(
                date: Date(),
                totalEquity: "12345.67",
                walletBalance: "9876.54",
                connectionStatus: "Connected",
                lastUpdate: Date()
            ))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            .previewDisplayName("Lock Screen - Inline")
        }
    }
} 
