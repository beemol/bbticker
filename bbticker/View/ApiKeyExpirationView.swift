//
//  ApiKeyExpirationView.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 8/3/26.
//

import SwiftUI
import LLCore

struct ApiKeyExpirationView: View {
    let state: ApiKeyExpirationState
    
    var body: some View {
        VStack {
            switch state.loadingState {
            case .idle:
                Text("API Key")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            case .loading:
                ProgressView()
                    .controlSize(.small)
            case .success:
                if let info = state.info {
                    if let deadlineDay = info.deadlineDay {
                        if deadlineDay < 0 {
                            VStack(spacing: 2) {
                                Text("API Key")
                                    .font(.subheadline)
                                Text("Expired")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        } else if deadlineDay < 7 {
                            VStack(spacing: 2) {
                                Text("API Key")
                                    .font(.subheadline)
                                Text("\(deadlineDay)d left")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        } else {
                            VStack(spacing: 2) {
                                Text("API Key")
                                    .font(.subheadline)
                                Text("\(deadlineDay)d left")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    } else {
                        VStack(spacing: 2) {
                            Text("API Key")
                                .font(.subheadline)
                            Text("Active")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            case .failure:
                VStack(spacing: 2) {
                    Text("API Key")
                        .font(.subheadline)
                    Text("Error")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
