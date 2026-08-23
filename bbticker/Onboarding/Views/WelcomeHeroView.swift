//
//  WelcomeHeroView.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import SwiftUI

// MARK: - Implementation plan (learning path: Graphics Performance)
//
// Goal: page 1 hero — an animated "live balance" sparkline.
//
// 1. SparklineCanvas (Graphics/) does the actual drawing with `Canvas`:
//    - ONE draw pass for the whole chart (path stroke + gradient fill),
//      instead of dozens of tiny shape views.
//    - `progress` (0...1) reveals the line gradually.
// 2. THIS view drives the animation with `TimelineView(.animation)`:
//    - The closure re-runs each frame, but no @State mutation happens, so
//      SwiftUI never re-evaluates the surrounding view tree — only the
//      canvas redraws. (Contrast: an onReceive/Timer + @State ticker
//      invalidates the whole body every frame.)
// 3. Later: the parallax exercise — this hero is placed inside the pager
//    and a GeometryReader in OnboardingView reads its scroll offset to
//    translate/scale the hero. Keep the GeometryReader OUT of this view
//    so only the pager subtree pays the layout cost.
struct WelcomeHeroView: View {
    private let values: [Double] = WelcomeHeroView.demoValues(count: 12)
    private let cycleDuration: TimeInterval = 4 // seconds per full cycle

    var body: some View {
        TimelineView(.animation) { context in

            let cycle = context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: cycleDuration)
            
            let progress = cycle / cycleDuration

            SparklineCanvas(values: values, progress: progress)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
        }
    }

    private static func demoValues(count: Int) -> [Double] {
        // Explicit loop (instead of a dense `map` closure) keeps the type
        // checker happy and is just as fast for 24 points.
        var values: [Double] = []
        values.reserveCapacity(count)
        for i in 0..<count {
            let index = Double(i)
            let wave = 30.0 * sin(index / 2.5)
            let ripple = 12.0 * sin(index * 1.3)
            values.append(50.0 + wave + ripple)
        }
        return values
    }
}

#Preview("Welcome Hero") {
    WelcomeHeroView()
        .padding()
        .frame(width: 300)
}
