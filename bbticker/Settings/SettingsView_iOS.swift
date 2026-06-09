import SwiftUI
import Intents

#if !os(macOS)
struct SettingsView_iOS: View {
    @ObservedObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var didInitialLoad = false
    @State private var siriAuthorizationStatus: INSiriAuthorizationStatus = .notDetermined
    @State private var apiCredentialsState: ApiCredentialsState
        
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
                //apiCredentialsSection
                //importantNotesSection
                //credentialButtonsSection
                saveStatusSection
                //widgetSettingsSection
                siriSettingsSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                AnalyticsManager.shared.track(.settingsOpened)
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
            if !apiCredentialsState.saveStatus.isEmpty {
                Text(apiCredentialsState.saveStatus)
                    .foregroundColor(apiCredentialsState.saveStatusColor)
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

    private var siriSettingsSection: some View {
        Section("Voice Commands") {
            // Show authorization status
            HStack {
                Text("Siri Status:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(siriStatusText)
                    .foregroundColor(siriStatusColor)
            }
            
            Button("Set up \"Hey Siri\" Commands") {
                SiriManager.shared.setupModernSiri()
                // Update status after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    siriAuthorizationStatus = INPreferences.siriAuthorizationStatus()
                }
            }
            
            if siriAuthorizationStatus == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Try saying:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• \"Hey Siri, what's my \(getAppName()) balance?\"")
                    .font(.caption)
                    .italic()
                Text("• \"Hey Siri, check my balance in \(getAppName())\"")
                    .font(.caption)
                    .italic()
            }
        }
        .onAppear {
            siriAuthorizationStatus = INPreferences.siriAuthorizationStatus()
        }
    }
    
    private var siriStatusText: String {
        switch siriAuthorizationStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not Set Up"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var siriStatusColor: Color {
        switch siriAuthorizationStatus {
        case .authorized:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
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
