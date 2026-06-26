//
//  MenuBarLabelView.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 01/12/2025.
//

import SwiftUI
import AppKit

struct MenuBarLabelView: View {
    @Bindable var walletState: WalletState
    var settingsService: SettingsService
    let isStale: Bool
    
    private var showsMarginLevelDot: Bool {
        settingsService.state.isProActive && settingsService.state.showMarginLevelDot
    }
    
    var body: some View {
        Image(nsImage: generateMenuBarImage(showMarginLevelDot: showsMarginLevelDot))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .accessibilityIdentifier(AccessibilityID.menuBarStatusItem)
    }
    
    private func generateMenuBarImage(showMarginLevelDot: Bool) -> NSImage {
        let text = String(format: "%.1f", walletState.equity)
        let font = NSFont.systemFont(ofSize: 12, weight: .medium)
        
        // Determine text color based on connection and stale state
        let textColor: NSColor
        if walletState.equity == 0 {
            textColor = NSColor.lightGray  // Disconnected state
        } else if isStale {
            textColor = NSColor.lightGray  // Stale data
        } else {
            textColor = NSColor.white      // Fresh data
        }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let dotSize: CGFloat = showMarginLevelDot ? 8 : 0
        let spacing: CGFloat = showMarginLevelDot ? 8 : 0
        let padding: CGFloat = 0
        let verticalPadding: CGFloat = 0
        
        let imageSize = CGSize(
            width: (showMarginLevelDot ? dotSize + spacing : 0) + textSize.width + (padding * 2),
            height: max(showMarginLevelDot ? dotSize : textSize.height, textSize.height) + (verticalPadding * 2)
        )
        
        // Create image
        let image = NSImage(size: imageSize)
        
        image.lockFocus()
        
        // Calculate positions
        let dotY = (imageSize.height - dotSize) / 2
        let textY = (imageSize.height - textSize.height) / 2
        
        if showMarginLevelDot {
            // Draw margin level indicator dot
            let dotRect = CGRect(
                x: padding,
                y: dotY,
                width: dotSize,
                height: dotSize
            )
            
            let marginColor = getMarginLevelColor()
            marginColor.setFill()
            
            let dotPath = NSBezierPath(ovalIn: dotRect)
            dotPath.fill()
            
            // Add subtle border to the dot for better visibility
            NSColor.white.withAlphaComponent(0.3).setStroke()
            dotPath.lineWidth = 0.5
            dotPath.stroke()
        }
        
        // Draw text
        let textRect = CGRect(
            x: padding + (showMarginLevelDot ? dotSize + spacing : 0),
            y: textY,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        
        image.unlockFocus()
        
        return image
    }
    
    private func getMarginLevelColor() -> NSColor {
        guard walletState.equity != 0 else {
            return NSColor.gray  // Disconnected state
        }
        
        let clampedMargin = walletState.maintenanceMarginPercentage
        
        // Apply dimming if data is stale
        let opacity: CGFloat = isStale ? 0.5 : 1.0
        
        if clampedMargin >= 70.0 {
            // High risk - red
            return NSColor.red.withAlphaComponent(opacity)
        } else if clampedMargin >= 50.0 {
            // Warning - yellow/orange
            return NSColor.orange.withAlphaComponent(opacity)
        } else {
            // Safe - green
            return NSColor.green.withAlphaComponent(opacity)
        }
    }
    
    /// Calculates background color based on maintenance margin level
    /// 0-50%: Bright green → Shaded green (safe zone)
    /// 50-100%: Shaded green → Bright red (danger zone)
    private var backgroundGradient: Color {
        guard walletState.equity != 0 else {
            return Color.gray.opacity(0.5)  // Disconnected state
        }
        
        let clampedMargin = walletState.maintenanceMarginPercentage  // Clamp between 0-100
        
        // Dim colors when data is stale
        let opacity: Double = isStale ? 0.5 : 1.0
        
        if clampedMargin <= 50 {
            // Green zone (0-50%): Bright green → Shaded green
            let progress = clampedMargin / 50.0  // 0.0 to 1.0
            let brightness = 1.0 - (progress * 0.5)  // 1.0 to 0.5
            return Color.green.opacity(brightness * opacity)
        } else {
            // Red zone (50-100%): Shaded green → Bright red
            let progress = (clampedMargin - 50) / 50.0  // 0.0 to 1.0
            
            // Interpolate from shaded green to bright red
            let greenComponent = 0.5 * (1.0 - progress)  // Green fades out
            let redComponent = progress  // Red fades in
            
            return Color(
                red: (0.5 + (redComponent * 0.5)) * opacity,  // 0.5 → 1.0, dimmed if stale
                green: greenComponent * opacity,               // 0.5 → 0.0, dimmed if stale  
                blue: 0
            )
        }
    }
}

// MARK: - Preview with Interactive Control
#if DEBUG
struct MenuBarLabelView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarLabelViewPreview()
            .frame(width: 400, height: 300)
            .padding()
    }
}

struct MenuBarLabelViewPreview: View {
    @State private var maintenanceMargin: Double = 0
    @State private var isStale: Bool = false
    @State private var showMarginLevelDot: Bool = true
    @State private var previewSettingsService = SettingsService()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Maintenance Margin Preview")
                .font(.headline)
            
            // The actual menu bar label view
            MenuBarLabelView(
                walletState: previewWalletState,
                settingsService: previewSettingsService,
                isStale: isStale
            )
                .scaleEffect(3.0)  // Make it bigger for preview
            
            // Stale data toggle
            Toggle("Stale Data", isOn: $isStale)
                .padding(.horizontal)
            
            Toggle("Margin Level Dot", isOn: $showMarginLevelDot)
                .padding(.horizontal)
                .onChange(of: showMarginLevelDot) { _, enabled in
                    previewSettingsService.setShowMarginLevelDot(enabled)
                }
            
            // Current values display
            VStack(spacing: 8) {
                Text("Maintenance Margin: \(Int(maintenanceMargin))%")
                    .font(.title2)
                    .bold()
                
                Text(riskZone)
                    .font(.subheadline)
                    .foregroundColor(riskColor)
                
                // Stale indicator
                if isStale {
                    Text("Showing Stale Data")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            
            // Interactive slider
            VStack(spacing: 10) {
                Slider(value: $maintenanceMargin, in: 0...100, step: 1)
                    .padding(.horizontal)
                
                HStack {
                    Text("0%")
                        .foregroundColor(.green)
                    Spacer()
                    Text("50%")
                        .foregroundColor(.orange)
                    Spacer()
                    Text("100%")
                        .foregroundColor(.red)
                }
                .font(.caption)
                .padding(.horizontal)
            }
            
            // Quick test buttons
            HStack(spacing: 10) {
                Button("Safe (10%)") { maintenanceMargin = 10 }
                Button("Warning (50%)") { maintenanceMargin = 50 }
                Button("Danger (75%)") { maintenanceMargin = 75 }
                Button("Critical (95%)") { maintenanceMargin = 95 }
            }
            .buttonStyle(.bordered)
        }
        .onAppear {
            previewSettingsService.applyProStatus(true)
            previewSettingsService.setShowMarginLevelDot(showMarginLevelDot)
        }
    }
    
    private var previewWalletState: WalletState {
        let state = WalletState()
        state.equity = 1234.5
        state.balance = 1000.0
        state.maintenanceMarginPercentage = maintenanceMargin
        return state
    }
    
    private var riskZone: String {
        if maintenanceMargin <= 50 {
            return "Safe Zone"
        } else if maintenanceMargin <= 75 {
            return "Warning Zone"
        } else {
            return "Danger Zone"
        }
    }
    
    private var riskColor: Color {
        if maintenanceMargin <= 50 {
            return .green
        } else if maintenanceMargin <= 75 {
            return .orange
        } else {
            return .red
        }
    }
}
#endif
