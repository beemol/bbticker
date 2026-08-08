//
//  ApiCredentialsSection.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 31/10/2025.
//

import SwiftUI
import LLCore

struct ApiCredentialsSection: View {
    @State private var state: ApiCredentialsState
    
    @State private var isShowingAlert = false
    
    init(settingsService: any SettingsServiceProtocol,
         credentialManager: CredentialManagerProtocol) {
        self._state = State(wrappedValue: ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        ))
    }
    
    init(state: ApiCredentialsState) {
        self._state = State(wrappedValue: state)
    }
    
    var body: some View {
        Group {
            Section("API Credentials") {
                TextField("API Key", text: $state.apiKey)
                    .autocorrectionDisabled()
                
                HStack {
                    if state.isSecureField {
                        SecureField("API Secret", text: $state.apiSecret)
                            .autocorrectionDisabled()
                    } else {
                        TextField("API Secret", text: $state.apiSecret)
                            .autocorrectionDisabled()
                    }
                    Button(action: {
                        state.toggleSecureField()
                    }) {
                        Image(systemName: state.isSecureField ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                // Only show passphrase field for KuCoin
                if state.requiresPassphrase {
                    TextField("API Passphrase", text: $state.apiPassphrase)
                        .autocorrectionDisabled()
                }
            }
            
            credentialButtonsSection
        }
        .onAppear {
            Task { await state.loadCredentials() }
        }
        .onChange(of: state.settingsService.state.exchangeType) {
            Task { await state.loadCredentials()}
        }
        .onChange(of: state.saveStatus.isShowing) { _, isShowing in
            isShowingAlert = isShowing
        }
        .alert(state.saveStatus.message, isPresented: $isShowingAlert) {
            Button("OK") { state.saveStatus = .idle }
        }
    }
    
    private var credentialButtonsSection: some View {
        Section {
            HStack(spacing: 8) {
                Button {
                    Task {
                        await state.saveCredentials()
                    }
                } label: {
                    Text("Save Credentials")
                        .lineLimit(1)
                }
                .disabled(!state.canSaveCredentials)
                .buttonStyle(.borderedProminent)
                
                Button {
                    Task {
                        await state.deleteCredentials()
                    }
                } label: {
                    Text("Delete Credentials")
                        .lineLimit(1)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                
                #if (macOS)
                Spacer()
                #endif
            }
        }
    }
}

#if DEBUG
struct ApiCredentialsSection_Previews: PreviewProvider {
    static var previews: some View {
        ApiCredentialsSection(settingsService: Mocks.MockSettingsService(), credentialManager: Mocks.MockCredentialManager())
            .frame(width: 500, height: 450)
    }
}
#endif
