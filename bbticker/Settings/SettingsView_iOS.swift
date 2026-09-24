import SwiftUI
import LLCore

#if !os(macOS)
struct SettingsView_iOS: View {
    @ObservedObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var didInitialLoad = false
    @State private var apiCredentialsState: ApiCredentialsState
    @State private var shortcutsStatusMessage: String?
    @State private var isConfiguringShortcuts = false
        
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        self._apiCredentialsState = State(wrappedValue: ApiCredentialsState(
            settingsService: viewModel.settingsService,
            credentialManager: viewModel.credentialManager
        ))
    }

    var body: some View {
        NavigationView {
            Form {
                ExchangeTypeSection(
                    settingsService: viewModel.settingsService
                )
                ApiCredentialsSection (state: apiCredentialsState)
                apiEnvironmentSection
                //apiCredentialsSection
                //importantNotesSection
                //credentialButtonsSection
                saveStatusSection
                //widgetSettingsSection
                siriSettingsSection
                balanceNotificationsSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await AnalyticsManager.shared.track(.settingsOpened)
                }
                if didInitialLoad == false {
                    didInitialLoad = true
                    Task { await viewModel.performInitialLoad() }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - View Components

    private var apiEnvironmentSection: some View {
        Section {
            Picker("API Environment", selection: viewModel.settingsService.selectedAPIEnvironmentBinding) {
                ForEach(viewModel.settingsService.availableAPIEnvironments, id: \.self) { env in
                    Text(env.rawValue.capitalized).tag(env)
                }
            }
        } header: {
            Text("API Environment")
        } footer: {
            Text("Select which environment to connect to.")
        }
    }

    private var importantNotesSection: some View {
        Section("Important Notes") {
            Text("1. Create your API Key on the exchange website.")
            Text("2. Grant READ-ONLY permissions only (e.g., 'Account' or 'Wallet').")
            Text("3. NEVER enable 'Trade' or 'Withdrawal' permissions for this app.")
            Text("4. Your keys are stored securely in your device's Keychain.")
        }
    }

    private var saveStatusSection: some View {
        Group {
            if !apiCredentialsState.saveStatus.message.isEmpty {
                Text(apiCredentialsState.saveStatus.message)
                    //.foregroundColor(apiCredentialsState.)
            }
        }
    }

    private var widgetSettingsSection: some View {
        Section("Widget Settings") {
            Toggle("Enable Widget", isOn: viewModel.widgetEnabledBinding)

            HStack {
                Text("Refresh Interval")
                Spacer()
                Picker("", selection: viewModel.widgetRefreshIntervalBinding) {
                    Text("30 sec").tag(0.5)
                    Text("1 min").tag(1.0)
                    Text("5 min").tag(5.0)
                    Text("15 min").tag(15.0)
                    Text("30 min").tag(30.0)
                }
                .pickerStyle(MenuPickerStyle())
            }

            Text("Widget shows your total equity on the home screen")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var balanceNotificationsSection: some View {
        Section {
            Toggle("Balance Notifications", isOn: viewModel.balanceNotificationsEnabledBinding)
            Text("Receive a notification with your current equity whenever the app refreshes in the background.")
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Text("Notifications")
        }
    }

    private var siriSettingsSection: some View {
        Section("Voice Commands & Shortcuts") {
            Button(isConfiguringShortcuts ? "Updating..." : "Update \"Hey Siri\" Shortcuts") {
                isConfiguringShortcuts = true
                Task {
                    let result = await SiriManager.shared.setupModernSiri()
                    isConfiguringShortcuts = false
                    switch result {
                    case .success:
                        shortcutsStatusMessage = "Shortcuts successfully registered with Siri!"
                    case .failure(let err):
                        shortcutsStatusMessage = "Setup error: \(err)"
                    }
                }
            }
            .disabled(isConfiguringShortcuts)

            if let message = shortcutsStatusMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Try saying:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• \"Hey Siri, what's my \(getAppName()) balance\"")
                    .font(.caption)
                    .italic()
                Text("• \"Hey Siri, check my balance in \(getAppName())\"")
                    .font(.caption)
                    .italic()
                Text("• \"Hey Siri, get my \(getAppName()) balance\"")
                    .font(.caption)
                    .italic()
            }
            
            Text("Tip: You can also open the iOS Shortcuts app and search for \"\(getAppName())\" to run the balance action directly.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#if DEBUG
struct SettingsView_iOS_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView_iOS(viewModel: Mocks.MockSettingsViewModel())
    }
}
#endif

#endif // !os(macOS)
