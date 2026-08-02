//
//  NetworkStatusView.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 8/2/26.
//

import SwiftUI

/// Reusable view to display network status from NetworkStore
struct NetworkStatusView: View {
    let state: NetworkState
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: state.connectionType.imageName)
//                .font(.system(size: 16))
                .foregroundColor(statusColor)
            
//            Text(statusText)
//                .font(.subheadline)
//                .foregroundColor(statusColor)
//                .lineLimit(1)
//                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var statusColor: Color {
        switch state.internetStatus {
        case .reachable:
            return .green
        case .checking:
            return .yellow
        case .unavailable, .unreachable:
            return .red
        }
    }
    
    private var statusText: String {
        switch state.internetStatus {
        case .reachable:
            return "Connected"
        case .checking:
            return "Checking..."
        case .unavailable:
            return "Unavailable"
        case .unreachable:
            return "No Internet"
        }
    }
}

// MARK: - Preview

#Preview("Interactive Controls") {
    NetworkStatusPreview()
}

#Preview("All States") {
    VStack(spacing: 20) {
        NetworkStatusView(state: NetworkState(
            isConnected: true,
            internetStatus: .reachable,
            connectionType: .wifi
        ))
        .padding()
        .background(Color.gray.opacity(0.1))
        
        NetworkStatusView(state: NetworkState(
            isConnected: true,
            internetStatus: .checking,
            connectionType: .wifi
        ))
        .padding()
        .background(Color.gray.opacity(0.1))
        
        NetworkStatusView(state: NetworkState(
            isConnected: false,
            internetStatus: .unavailable,
            connectionType: .unknown
        ))
        .padding()
        .background(Color.gray.opacity(0.1))
        
        NetworkStatusView(state: NetworkState(
            isConnected: true,
            internetStatus: .unreachable,
            connectionType: .cellular
        ))
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    .padding()
}

private struct NetworkStatusPreview: View {
    @State private var isConnected = false
    @State private var internetStatus: InternetStatus = .unavailable
    @State private var connectionType: NetworkStore.ConnectionType = .unknown
    
    private var previewState: NetworkState {
        NetworkState(
            isConnected: isConnected,
            internetStatus: internetStatus,
            connectionType: connectionType
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Preview Area
            VStack(spacing: 12) {
                Text("Preview")
                    .font(.headline)
                
                NetworkStatusView(state: previewState)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                // State Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Path Available:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(isConnected ? "Yes" : "No")
                            .bold()
                    }
                    HStack {
                        Text("Internet Reachable:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(previewState.isInternetReachable ? "Yes" : "No")
                            .bold()
                    }
                }
                .font(.caption)
                .padding(.horizontal)
            }
            
            Divider()
            
            // Controls
            VStack(alignment: .leading, spacing: 16) {
                Text("Controls")
                    .font(.headline)
                
                // Quick Presets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Presets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Button("🟢 Connected") {
                            isConnected = true
                            internetStatus = .reachable
                            connectionType = .wifi
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        
                        Button("🟡 Checking") {
                            isConnected = true
                            internetStatus = .checking
                            connectionType = .wifi
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        
                        Button("🔴 Disconnected") {
                            isConnected = false
                            internetStatus = .unavailable
                            connectionType = .unknown
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                
                // Path Status Toggle
                VStack(alignment: .leading, spacing: 4) {
                    Text("Network Path")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Toggle("Path Available", isOn: $isConnected)
                }
                
                // Internet Status Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Internet Status")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("Internet Status", selection: $internetStatus) {
                        Text("Unavailable").tag(InternetStatus.unavailable)
                        Text("Checking").tag(InternetStatus.checking)
                        Text("Reachable").tag(InternetStatus.reachable)
                        Text("Unreachable").tag(InternetStatus.unreachable)
                    }
                    .pickerStyle(.segmented)
                }
                
                // Connection Type Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connection Type")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("Connection Type", selection: $connectionType) {
                        Text("Unknown").tag(NetworkStore.ConnectionType.unknown)
                        Text("WiFi").tag(NetworkStore.ConnectionType.wifi)
                        Text("Cellular").tag(NetworkStore.ConnectionType.cellular)
                        Text("Ethernet").tag(NetworkStore.ConnectionType.ethernet)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding()
        }
        .padding()
        .frame(width: 450)
    }
}
