import SwiftUI

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
                ExchangeTypeSection(settingsService: viewModel.settingsService)
                ApiCredentialsSection (settingsService: viewModel.settingsService, credentialManager: viewModel.credentialManager)
                apiKeyCreationSection
                updateFrequencySection
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
    
    private var updateFrequencySection: some View {
        Section("Update Frequency (Paid Feature)") {
            VStack(alignment: .leading, spacing: 12) {
                Text("How often should the app update your balance data?")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Picker("Update Frequency", selection: viewModel.updateFrequencyBinding) {
                    Text("1 second").tag(1.0)
                    Text("5 seconds").tag(5.0)
                    Text("15 seconds").tag(15.0)
                }
                .pickerStyle(.segmented)
                .disabled(!viewModel.isUpdateFrequencyUnlocked)

                if !viewModel.isUpdateFrequencyUnlocked {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill").foregroundColor(.orange)
                        Text("Unlock faster updates with a one‑time purchase.")
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
                    .padding(.top, 4)
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
