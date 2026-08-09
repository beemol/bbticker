//
//  bbtickerApp.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 03/07/2025.
//

import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif
import AppIntents
import Combine
#if os(macOS)
import AppKit
#endif

@main
struct bbtickerApp: App {
    
    // Static flag to prevent multiple Firebase configuration
    private static var isFirebaseConfigured = false
    
    #if os(macOS) && STANDALONE
    @StateObject private var updaterController = SparkleUpdater()
    #endif
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @State private var menuBarTick: Int = 0
    #endif
    
    #if !os(macOS)
    // TODO: DO we need to keep BackgroundTaskManager as StateObject here?
    private var backgroundTaskManager: BackgroundTaskManager
    #endif
    
    @State private var showSettings = false
    @State private var accountIdentifier: String = "defaultUser"
    
    // Track app launch time
    private let appLaunchStartTime = Date()
    
    @StateObject private var settingsService: SettingsService
    private let networkMonitor = NetworkStore()
    @StateObject private var remoteConfigManager: RemoteConfigManager
    
    private let bybitClient: BBClient
    private let settingsViewModel: SettingsViewModel
    #if !APP_STORE
    private let donationViewModel: DonationViewModel
    #endif
    private let disableCenter = DisableCenter()

    init() {
        // Configure Firebase only once
        #if canImport(FirebaseCore)
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil,
           !Self.isFirebaseConfigured {

            FirebaseConfiguration.shared.setLoggerLevel(.error)
            FirebaseApp.configure()
            Self.isFirebaseConfigured = true
        }
        #endif
        
        // Create dependencies as local variables
        let credentialManager = CredentialManager(keychainHelper: KeychainHelper.shared)
        let settings = SettingsService()
        let analyticsManager = AnalyticsManager.shared
        let remoteConfig = RemoteConfigManager()
        
        let apiService = LLAPIServiceWrapper(
            credentialManager: credentialManager,
            settingsService: settings,
            urlSession: URLSession.shared
        )
        
        // Register dependencies in the container for AppIntents and other global access
        DependencyContainer.shared.register(
            settingsService: settings,
            credentialManager: credentialManager
        )
        
        bybitClient = BBClient(
            settingsService: settings,
            networkMonitor: networkMonitor,
            sharedDataManager: SharedDataManager.shared,
            walletRepository: WalletRepository(credentialManager: credentialManager, apiService: apiService)
        )

        // Wrap them in StateObject
        _settingsService = StateObject(wrappedValue: settings)
        _remoteConfigManager = StateObject(wrappedValue: remoteConfig)
        
        settingsViewModel = SettingsViewModel(
            settingsService: settings,
            credentialManager: credentialManager,
            sharedDataService: SharedDataManager.shared,
            iapManager: IAPManager.shared
        )
        
        Task {
            await IAPManager.shared.startObservingTransactions { isPro in
                Task { @MainActor in
                    settings.applyProStatus(isPro)
                }
            }
        }
        
        #if !APP_STORE
        donationViewModel = DonationViewModel(remoteConfigManager: remoteConfig)
        #endif
        
        #if !os(macOS)
        backgroundTaskManager = BackgroundTaskManager(apiService: apiService)
        SiriManager.shared.setupModernSiri()
        #endif
        
        let launchDuration = Date().timeIntervalSince(appLaunchStartTime)
        Task {
            await analyticsManager.track(.appLaunch)
            await analyticsManager.track(.appLaunchTime(duration: launchDuration))
        }
    }
    
    var body: some Scene {
        #if os(macOS)
        MenuBarExtra(content: {
            MenuBarPopoverView(
                bybitClient: bybitClient,
                networkMonitor: networkMonitor,
                disableCenter: disableCenter,
                accountIdentifier: accountIdentifier,
                openSettings: {
                    openWindow(id: "settings")
                },
                openDonation: {
                    openWindow(id: "donation")
                }
            )
            .onAppear {
                Task {
                    await remoteConfigManager.refreshAllConfigurations()
                }
            }
            .environmentObject(settingsService)
        }, label: {
            MenuBarLabelView(
                walletState: bybitClient.walletState,
                settingsService: settingsService,
                isStale: bybitClient.$walletState.isStale
            )
        })
        .menuBarExtraStyle(.window)
        #if os(macOS) && STANDALONE
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…", action: {
                    self.updaterController.checkForUpdates()
                })
                .keyboardShortcut("U", modifiers: [.command, .shift])
            }
        }
        #endif
        
        Window("Settings", id: "settings") {
            SettingsView_macOS(viewModel: settingsViewModel)
                .onAppear {
                    keepWindowOnTop(withTitle: "Settings")
                }
        }
        .windowResizability(.contentSize)
        
        #if !APP_STORE
        Window("Support BBTicker", id: "donation") {
            DonationView(viewModel: donationViewModel)
                .frame(minWidth: 600, minHeight: 550)
                .environmentObject(settingsService)
                .onAppear {
                    keepWindowOnTop(withTitle: "Support BBTicker")
                }
        }
        .windowResizability(.contentSize)
        #endif
        #else
        WindowGroup {
            ContentView()
                .environmentObject(bybitClient)
                .environmentObject(networkMonitor)
                .environmentObject(settingsService)
                .environmentObject(settingsViewModel)
                .onAppear {
                    
                    backgroundTaskManager.scheduleBackgroundTasks()
                    
                    Task {
                        await remoteConfigManager.refreshAllConfigurations()
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView_iOS(viewModel: settingsViewModel)
                }
        }
        #endif
    }
    
    // MARK: - Window Management Methods
    #if os(macOS)
    private func keepWindowOnTop(withTitle: String) {
        DispatchQueue.main.async {
            if let settingsWindow = NSApp.windows.first(where: { $0.title == withTitle }) {
                settingsWindow.level = .floating
                settingsWindow.makeKeyAndOrderFront(nil)
                settingsWindow.orderFrontRegardless()
            }
        }
    }
    #endif
}
