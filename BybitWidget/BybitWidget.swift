//
//  BybitWidget.swift
//  BybitWidget
//
//  Created by Aleh Fiodarau on 25/07/2025.
//

import WidgetKit
import SwiftUI

struct BybitWidget: Widget {
    let kind: String = "BybitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BybitTimelineProvider()) { entry in
            BybitWidgetView(entry: entry)
        }
        .configurationDisplayName("Balance Tracker")
        .description("Shows your crypto balance in real-time")
        .supportedFamilies([
            // Home Screen widgets
            .systemSmall,
            .systemMedium,
            // Lock Screen widgets (iOS 16+)
            .accessoryCircular,      // Small circle on Lock Screen
            .accessoryRectangular,   // Wide rectangle on Lock Screen
            .accessoryInline         // Text in notification area
        ])
    }
}

struct BybitWidget_Previews: PreviewProvider {
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
