//
//  StaleTracked.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 05/06/2026.
//

import SwiftUI

@MainActor
@Observable
@propertyWrapper
class StaleTracked<T> {
    private(set) var data: T
    private(set) var lastUpdated: Date?
    private(set) var isStale: Bool = true
    
    private var timer: Timer?
    private var threshold: TimeInterval
    
    var wrappedValue: T {
        get {
            data
        }
        set {
            markFresh(with: newValue)
        }
    }
    
    var projectedValue: StaleTracked<T> { self }
    
    init(wrappedValue: T, stale: Bool = false, threshold: TimeInterval = 5.0) {
        self.data = wrappedValue
        self.threshold = threshold
        
        stale ? markStale() : markFresh(with: wrappedValue)
    }
    
    func markFresh(with newData: T) {
        timer?.invalidate()
        
        data = newData
        lastUpdated = Date()
        isStale = false
        startTimer(with: lastUpdated)
    }
    
    func markStale() {
        isStale = true
        timer?.invalidate()
    }
    
    func set(threshold: Double) {
        self.threshold = threshold
    }
    
    private func startTimer(with lastUpdated: Date?) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: threshold, repeats: false) { _ in
            Task { @MainActor [weak self] in
                if self?.lastUpdated == lastUpdated {
                    self?.isStale = true
                }
            }

        }
    }
}
