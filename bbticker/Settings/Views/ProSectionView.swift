//
//  ProSectionView.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 11/27/26.
//


import SwiftUI
import Combine

struct ProSectionView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                proFeatureControls
                    .disabled(!viewModel.isProActive)
                    .opacity(viewModel.isProActive ? 1 : 0.45)
                
                if !viewModel.isProActive {
                    proUnlockFooter
                }
            }
        } header: {
            Text("BBTicker Pro")
        } footer: {
            if viewModel.isProActive {
                Text("Pro features are active on this device.")
            } else {
                Text("Free tier uses 15 second balance updates. Unlock Pro with a one-time purchase.")
            }
        }
    }
    
    private var proFeatureControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Update frequency", systemImage: "arrow.triangle.2.circlepath")
                    .font(.callout)
                    .fontWeight(.medium)
                
                Text("How often the app refreshes your balance data.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Update Frequency", selection: viewModel.updateFrequencyBinding) {
                    Text("1 second").tag(1.0)
                    Text("5 seconds").tag(5.0)
                    Text("10 seconds").tag(10.0)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            
            Toggle(isOn: viewModel.showMarginLevelDotBinding) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Margin level dot", systemImage: "circle.fill")
                        .font(.callout)
                        .fontWeight(.medium)
                    Text("Show a colored dot in the menu bar indicating your maintenance margin level.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
        }
    }
    
    private var proUnlockFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
                Text("Unlock faster updates and the margin level dot.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Unlock") {
                    viewModel.unlockUpdateFrequency()
                }
                .buttonStyle(.borderedProminent)
                Button("Restore") {
                    viewModel.restorePurchases()
                }
            }
            
            switch viewModel.purchaseState {
            case .purchasing:
                Text("Purchasing…").font(.caption).foregroundColor(.secondary)
            case .restoring:
                Text("Restoring…").font(.caption).foregroundColor(.secondary)
            case .failed(let message):
                Text(message).font(.caption).foregroundColor(.red)
            default:
                EmptyView()
            }
        }
        .padding(.top, 4)
    }
}

struct ProSection_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            ProSectionView(viewModel: Mocks.MockSettingsViewModel())
                
        }.frame(width: 350, height: 350)
    }
}
