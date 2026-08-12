import SwiftUI
import LLCore

import Combine

//#if os(macOS)
struct SettingsView_macOS: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    @Environment(\.dismiss) var dismiss
    @State private var isAPIKeyCreationExpanded = false
    @State private var isImportantNotesExpanded = false
    @State private var apiKeySteps: [String] = []
    @State private var apiKeyNotes: String? = nil
    @State private var isShowingExchangeInfoPopover = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        //let _ = Self._printChanges()
        
        return VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            #if os(macOS)
            .background(Color(.controlBackgroundColor))
            #endif
            
            // Content
            Form {
                apiEnvironmentSection
                ExchangeTypeSection(settingsService: viewModel.settingsService)
                ApiCredentialsSection (settingsService: viewModel.settingsService, credentialManager: viewModel.credentialManager)
                apiKeyCreationSection
                proSection
                analyticsSection
                securitySection
                //importantNotesSection
                contactSection
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 500, minHeight: 600)
        .onAppear {
            Task { await AnalyticsManager.shared.track(.settingsOpened) }
            Task { await viewModel.performInitialLoad() }
            if let steps = viewModel.loadAPIKeySteps() {
                apiKeySteps = steps.steps
                apiKeyNotes = steps.notes
            }
        }

    }
    
    // MARK: - View Components

    private var apiDetailsView: some View {
        Image(systemName: "info.circle")
        .foregroundColor(.secondary)
        .onHover { hovering in
            isShowingExchangeInfoPopover = hovering
        }
        .popover(isPresented: $isShowingExchangeInfoPopover, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("API details for \(viewModel.exchangeType.displayName.capitalized)")
                    .font(.headline)
                Divider()
                Text("Base URL")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.exchangeType.baseURL)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .textSelection(.enabled)
                Text("Endpoint")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 6)
                Text(viewModel.exchangeType.endpoint)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .textSelection(.enabled)
            }
            .padding()
            .frame(maxWidth: 420, alignment: .leading)
        }
    }

    private var apiEnvironmentSection: some View {
        Section {
            Picker("API Environment", selection: viewModel.settingsService.selectedAPIEnvironmentBinding) {
                ForEach(viewModel.settingsService.availableAPIEnvironments, id: \.self) { env in
                    Text(env.rawValue.capitalized).tag(env)
                }
            }
            .pickerStyle(.menu)
        } footer: {
            Text("Select which environment to connect to. Production is the live trading environment. Testnet is for testing with simulated funds.")
        }
    }

    private var apiKeyCreationSection: some View {
        Section {
            DisclosureGroup(
                isExpanded: $isAPIKeyCreationExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Follow these steps to create your API key:")
                            .font(.callout)
                            .fontWeight(.medium)
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(apiKeySteps.indices, id: \.self) { idx in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(idx + 1).")
                                        .fontWeight(.medium)
                                    Text(apiKeySteps[idx])
                                }
                            }
                        }
                        .font(.callout)
                        if let notes = apiKeyNotes {
                            Text(notes)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.top, 8)
                },
                label: {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.accentColor)
                        Text("How to create an API key")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            )
        }
    }
    
    private var proSection: some View {
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
    
    private var analyticsSection: some View {
        Section("Privacy & Analytics") {
            Toggle(isOn: viewModel.analyticsEnabledBinding) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Anonymous usage data", systemImage: "chart.bar")
                        .font(.callout)
                        .fontWeight(.medium)
                    Text("Help improve BBTicker by sharing anonymous app usage data. No personal or exchange information is ever collected. You can turn this off at any time.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            
            if let privacyURL = URL(string: "https://beemol.github.io/bbticker-releases/privacy.html") {
                Link("Privacy Policy", destination: privacyURL)
            }
        }
    }
    
    private var securitySection: some View {
        Section("Security & Disclaimer") {
            VStack(alignment: .leading, spacing: 12) {
                Label("Read-only access", systemImage: "eye")
                    .font(.callout)
                    .fontWeight(.medium)
                Text("BBTicker uses read-only API keys. It can never place trades or withdraw funds. Create keys with read-only permissions only.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("Secure storage", systemImage: "lock")
                    .font(.callout)
                    .fontWeight(.medium)
                Text("Your API keys are stored encrypted in the macOS Keychain and are sent only to your exchange over HTTPS.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("Not financial advice", systemImage: "exclamationmark.shield")
                    .font(.callout)
                    .fontWeight(.medium)
                Text("BBTicker is a monitoring tool and does not provide financial advice. Trading cryptocurrencies involves risk.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var contactSection: some View {
        Section("Contact Support") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let contactURL = URL(string: "https://beemol.github.io/bbticker-releases/contact.html"),
                       let issuesURL = URL(string: "https://github.com/beemol/bbticker-releases/issues") {
                        Link("Contact", destination: contactURL)
                        Text("or")
                        Link("Go to GitHub Issues", destination: issuesURL)
                    } else {
                        Text("fedorov.oleg@gmail.com")
                    }
                }
            }
            .font(.callout)
        }
    }

}

#if DEBUG
struct SettingsView_macOS_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView_macOS(viewModel: Mocks.MockSettingsViewModel())
            .frame(width: 500, height: 450)
    }
}
#endif

//#endif // os(macOS)
