//
//  PollingStrategy.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 28/11/2025.
//

import Foundation
import SwiftUI

enum ConnectionStatus: String, Sendable {
    case connected
    case disconnected
    case connecting
    
    var description: String {
        return self.rawValue.capitalized
    }
}

extension ConnectionStatus {
    var color: Color {
        switch self {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .red
        }
    }
}
