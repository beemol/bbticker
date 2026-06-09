import Foundation

// MARK: - Protocols for Dependency Injection

protocol KeychainServiceProtocol {
    func save(key: String, secret: String, passphrase: String, forAccount: String) async -> OSStatus
    func delete(account: String) async -> OSStatus
    func retrieve(forAccount: String, attribute: Attribute) async -> String?
    func retrieve(forAccount: String) async -> (String?, String?, String?)
}

#if DEBUG
class MockKeychainService: KeychainServiceProtocol {
    var saveResult: OSStatus = errSecSuccess
    var deleteResult: OSStatus = errSecSuccess
    var retrieveResult: (String?, String?, String?) = (nil, nil, nil)
    
    var savedCredentials: [(key: String, secret: String, account: String)] = []
    var deletedAccounts: [String] = []
    var retrieveCalls: [String] = []
    
    func save(key: String, secret: String, passphrase: String, forAccount: String) async -> OSStatus {
        savedCredentials.append((key: key, secret: secret, account: forAccount))
        return saveResult
    }
    
    func delete(account: String) async -> OSStatus {
        deletedAccounts.append(account)
        return deleteResult
    }
    
    // TODO: fix
    func retrieve(forAccount: String, attribute: Attribute) async -> String? {
        //retrieveCalls.append(forAccount)
        return nil
    }
    
    // TODO: fix
    func retrieve(forAccount: String) async -> (String?, String?, String?) {
        return (nil, nil, nil)
    }
}

//class MockSharedDataService: SharedDataManagerProtocol {
//    func updateWidgetData(totalEquity: String, walletBalance: String, connectionStatus: String) {
//        // No-op for testing
//    }
//    
//    var widgetEnabled: Bool = false
//    var widgetRefreshInterval: Double = 5.0
//    
//    var setWidgetEnabledCalls: [Bool] = []
//    var setWidgetRefreshIntervalCalls: [Double] = []
//    
//    func setWidgetEnabled(_ enabled: Bool) {
//        setWidgetEnabledCalls.append(enabled)
//        widgetEnabled = enabled
//    }
//    
//    func isWidgetEnabled() -> Bool {
//        return widgetEnabled
//    }
//    
//    func setWidgetRefreshInterval(_ interval: Double) {
//        setWidgetRefreshIntervalCalls.append(interval)
//        widgetRefreshInterval = interval
//    }
//    
//    func getWidgetRefreshInterval() -> Double {
//        return widgetRefreshInterval
//    }
//}
#endif 
