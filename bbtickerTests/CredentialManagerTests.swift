import XCTest
import LLCore
@testable import bbticker

final class CredentialManagerTests: XCTestCase {
    var keychain: MockKeychainHelper!
    var manager: CredentialManager!

    override func setUp() {
        super.setUp()
        keychain = MockKeychainHelper()
        manager = CredentialManager(keychainHelper: keychain)
    }

    override func tearDown() {
        manager = nil
        keychain = nil
        super.tearDown()
    }

    func testSaveCredentials_Success_CachesAndReturns() async throws {
        // Given
        await keychain.setNextSaveStatus(errSecSuccess)

        // When
        let status = await manager.saveCredentials(key: "k", secret: "s", passphrase: "p", forAccount: "acc")

        // Then
        XCTAssertEqual(status, errSecSuccess)

        // Should read from cache regardless of keychain changes
        await keychain.setStorage(account: "acc", key: "k2", secret: "s2", passphrase: "p2")
        let creds = try await manager.getCredentials(forAccount: "acc")
        XCTAssertEqual(creds.apiKey, "k")
        XCTAssertEqual(creds.apiSecret, "s")
        XCTAssertEqual(creds.passphrase, "p")
    }

    func testSaveCredentials_Failure_DoesNotCache() async throws {
        // Given
        await keychain.setNextSaveStatus(errSecItemNotFound)

        // When
        let status = await manager.saveCredentials(key: "k", secret: "s", passphrase: "p", forAccount: "acc")

        // Then
        XCTAssertEqual(status, errSecItemNotFound)

        // Since not cached, a subsequent get will look at keychain and throw (empty)
        await keychain.clear(account: "acc")
        await XCTAssertThrowsErrorAsync(try await self.manager.getCredentials(forAccount: "acc"))
    }

    func testGetCredentials_FetchesFromKeychain_WhenNotCached_ThenCaches() async throws {
        // Given
        await keychain.setStorage(account: "acc", key: "k", secret: "s", passphrase: nil)

        // When
        let first = try await manager.getCredentials(forAccount: "acc")

        // Then fetched from keychain
        XCTAssertEqual(first.apiKey, "k")
        XCTAssertEqual(first.apiSecret, "s")
        XCTAssertNil(first.passphrase)

        // Mutate keychain; cached result should still be returned
        await keychain.setStorage(account: "acc", key: "k2", secret: "s2", passphrase: "p2")
        let second = try await manager.getCredentials(forAccount: "acc")
        XCTAssertEqual(second.apiKey, "k")
        XCTAssertEqual(second.apiSecret, "s")
        XCTAssertNil(second.passphrase)
    }

    func testGetCredentials_Throws_WhenKeyOrSecretMissing() async {
        // Given: missing key and secret
        await keychain.setStorage(account: "acc", key: nil, secret: nil, passphrase: nil)

        // Then
        await XCTAssertThrowsErrorAsync(try await self.manager.getCredentials(forAccount: "acc"))
    }

    func testDeleteCredentials_Success_ClearsCache() async throws {
        // Given
        await keychain.setNextSaveStatus(errSecSuccess)
        _ = await manager.saveCredentials(key: "k", secret: "s", passphrase: "p", forAccount: "acc")
        await keychain.setNextDeleteStatus(errSecSuccess)

        // When
        let status = await manager.deleteCredentials(forAccount: "acc")

        // Then
        XCTAssertEqual(status, errSecSuccess)
        // After cache cleared, new fetch should reflect keychain
        await keychain.setStorage(account: "acc", key: "k2", secret: "s2", passphrase: nil)
        let creds = try await manager.getCredentials(forAccount: "acc")
        XCTAssertEqual(creds.apiKey, "k2")
        XCTAssertEqual(creds.apiSecret, "s2")
        XCTAssertNil(creds.passphrase)
    }

    func testDeleteCredentials_Failure_DoesNotClearCache() async throws {
        // Given
        await keychain.setNextSaveStatus(errSecSuccess)
        _ = await manager.saveCredentials(key: "k", secret: "s", passphrase: "p", forAccount: "acc")
        await keychain.setNextDeleteStatus(errSecItemNotFound)

        // When
        let status = await manager.deleteCredentials(forAccount: "acc")

        // Then
        XCTAssertEqual(status, errSecItemNotFound)
        // Cache should still return old values despite keychain change
        await keychain.setStorage(account: "acc", key: "k2", secret: "s2", passphrase: nil)
        let creds = try await manager.getCredentials(forAccount: "acc")
        XCTAssertEqual(creds.apiKey, "k")
        XCTAssertEqual(creds.apiSecret, "s")
        XCTAssertEqual(creds.passphrase, "p")
    }
}

// MARK: - Helpers

private extension XCTestCase {
    func XCTAssertThrowsErrorAsync<T>(_ expression: @autoclosure () async throws -> T) async {
        do {
            _ = try await expression()
            XCTFail("Expected error to be thrown")
        } catch {
            // success
        }
    }
}

actor MockKeychainHelper: KeychainHelperProtocol {
    var storage: [String: (key: String?, secret: String?, passphrase: String?)] = [:]
    var nextSaveStatus: OSStatus = errSecSuccess
    var nextDeleteStatus: OSStatus = errSecSuccess

    func save(key: String, secret: String, passphrase: String, forAccount account: String) async -> OSStatus {
        defer { nextSaveStatus = errSecSuccess }
        if nextSaveStatus == errSecSuccess {
            storage[account] = (key: key, secret: secret, passphrase: passphrase.isEmpty ? nil : passphrase)
        }
        return nextSaveStatus
    }

    func retrieve(forAccount: String) async -> (String?, String?, String?) {
        let vals = storage[forAccount] ?? (nil, nil, nil)
        return (vals.key, vals.secret, vals.passphrase)
    }

    func retrieve(forAccount: String, attribute: Attribute) async -> String? {
        let vals = storage[forAccount]
        switch attribute {
        case .key: return vals?.key
        case .secret: return vals?.secret
        case .passphrase: return vals?.passphrase
        }
    }

    func delete(account: String) async -> OSStatus {
        defer { nextDeleteStatus = errSecSuccess }
        if nextDeleteStatus == errSecSuccess {
            storage[account] = nil
        }
        return nextDeleteStatus
    }

    func clear(account: String) async {
        storage[account] = nil
    }
    
    // MARK: - Test Helper Methods
    
    func setNextSaveStatus(_ status: OSStatus) {
        nextSaveStatus = status
    }
    
    func setNextDeleteStatus(_ status: OSStatus) {
        nextDeleteStatus = status
    }
    
    func setStorage(account: String, key: String?, secret: String?, passphrase: String?) {
        storage[account] = (key: key, secret: secret, passphrase: passphrase)
    }
    
    func getStorage(forAccount account: String) -> (key: String?, secret: String?, passphrase: String?) {
        return storage[account] ?? (nil, nil, nil)
    }
}



// ---------------------------------------------------------------
// Reentrancy tests
// ---------------------------------------------------------------


#if canImport(Security)
import Security
#else
public typealias OSStatus = Int32
public let errSecSuccess: OSStatus = 0
#endif


// MARK: - AsyncGate (actor-safe)

/// A synchronization primitive that blocks tasks until explicitly opened.
/// Used to create controlled suspension points in async code for testing race conditions.
actor AsyncGate {
    private var isOpen = false
    private var waiter: CheckedContinuation<Void, Never>?

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { cont in
            waiter = cont
        }
    }

    func open() async {
        guard !isOpen else { return }
        isOpen = true
        waiter?.resume()
        waiter = nil
    }

    func reset() async {
        isOpen = false
        waiter = nil
    }
}

// MARK: - Gated wrapper that introduces a deterministic suspension point

/// GatedKeychainHelper is a test double that wraps MockKeychainHelper to simulate race conditions
/// in a controlled, deterministic way.
///
/// **Purpose:**
/// In real-world scenarios, race conditions happen unpredictably when async operations interleave.
/// This wrapper makes race conditions happen PREDICTABLY by introducing a controlled suspension point
/// in the `retrieve()` method, allowing us to test how CredentialManager handles reentrancy.
///
/// **The Reentrancy Problem Being Tested:**
/// When CredentialManager (an actor) calls `getCredentials()`, it:
/// 1. Checks cache (miss)
/// 2. Calls keychain.retrieve() to fetch credentials
/// 3. Caches the result
/// 4. Returns the credentials
///
/// The bug occurs when:
/// - Step 2 (retrieve) suspends (awaits)
/// - During that suspension, another operation (save/delete) modifies the cache
/// - Step 3 resumes and overwrites the cache with stale data from the keychain
///
/// **How GatedKeychainHelper Simulates This:**
/// 1. Takes a snapshot of keychain data IMMEDIATELY when retrieve() is called
/// 2. Suspends execution (via AsyncGate) - this is when the test can interleave other operations
/// 3. When released, returns the OLD snapshot (even if keychain was modified during suspension)
/// 4. This simulates the real-world scenario where keychain I/O takes time and data becomes stale
///
/// **Test Flow Example:**
/// ```
/// Task A: getCredentials() → retrieve() → [SNAPSHOT: old data] → [SUSPENDED at gate]
///         ↓ (while suspended, cache is empty)
/// Task B: saveCredentials() → [UPDATES cache with new data]
///         ↓
/// Task A: [RESUMED] → returns old snapshot → [BUG: overwrites cache with old data]
/// ```
actor GatedKeychainHelper: KeychainHelperProtocol {
    
    private let keychain: MockKeychainHelper
    
    // Two synchronization mechanisms working in opposite directions:
    // 1. gate: Blocks retrieve() from completing until test releases it (test → retrieve)
    // 2. retrieveStartedWaiter: Signals test when retrieve() has taken snapshot (retrieve → test)
    
    private let gate = AsyncGate()
    private var retrieveStartedWaiter: CheckedContinuation<Void, Never>?
    private var retrieveStartedFlag = false

    init(_ keychain: MockKeychainHelper) {
        self.keychain = keychain
    }

    func save(key: String, secret: String, passphrase: String, forAccount account: String) async -> OSStatus {
        await keychain.save(key: key, secret: secret, passphrase: passphrase, forAccount: account)
    }

    func retrieve(forAccount account: String) async -> (String?, String?, String?) {
        // Take snapshot immediately - this will be returned later even if storage changes
        let snap = await keychain.getStorage(forAccount: account)

        // Signal test that snapshot is taken
        if !retrieveStartedFlag {
            retrieveStartedFlag = true
            retrieveStartedWaiter?.resume()
            retrieveStartedWaiter = nil
        }

        // Suspend here to allow test to interleave other operations
        await gate.wait()

        // Return the stale snapshot (simulating slow I/O)
        return (snap.key, snap.secret, snap.passphrase)
    }

    func retrieve(forAccount account: String, attribute: Attribute) async -> String? {
        let (k, s, p) = await retrieve(forAccount: account)
        switch attribute {
        case .key: return k
        case .secret: return s
        case .passphrase: return p
        }
    }

    func delete(account: String) async -> OSStatus {
        await keychain.delete(account: account)
    }

    func clear(account: String) async {
        await keychain.clear(account: account)
    }

    // MARK: - Test Control Hooks

    /// Waits until retrieve() has taken its snapshot
    func waitUntilRetrieveStarted() async {
        if retrieveStartedFlag { return }
        await withCheckedContinuation { cont in
            retrieveStartedWaiter = cont
        }
    }

    /// Releases the suspended retrieve() call
    func releaseRetrieve() async {
        await gate.open()
    }

    /// Resets for next test
    func resetGate() async {
        retrieveStartedFlag = false
        retrieveStartedWaiter = nil
        await gate.reset()
    }
}

// MARK: - Reentrancy tests

/// Tests that verify CredentialManager handles actor reentrancy correctly.
/// Actors don't hold locks during suspension points (await), allowing other operations to interleave.
/// These tests simulate race conditions where stale data from slow I/O overwrites newer cached data.
final class CredentialManagerReentrancyTests: XCTestCase {

    /// Tests that an in-flight get() doesn't overwrite cache with stale data when save() runs concurrently.
    func test_GetDoesNotOverwriteNewerSavedCredentials_withoutFix() async throws {
        let base = MockKeychainHelper()
        let account = "acc-overwrite"
        await base.setStorage(account: account, key: "oldKey", secret: "oldSecret", passphrase: "oldPass")

        let helper = GatedKeychainHelper(base)
        let manager = CredentialManager(keychainHelper: helper)

        // Start get() - it will suspend with OLD snapshot
        // This STARTS the task but doesn't wait for it to complete
        async let firstGet: Credentials = try await manager.getCredentials(forAccount: account)
        // This waits until the retrieve() has taken its snapshot
        await helper.waitUntilRetrieveStarted()

        // While suspended, save NEW credentials
        let status = await manager.saveCredentials(
            key: "newKey",
            secret: "newSecret",
            passphrase: "newPass",
            forAccount: account
        )
        XCTAssertEqual(status, errSecSuccess)

        // Resume get() - it returns OLD snapshot
        // This opens the gate, allowing firstGet to complete
        await helper.releaseRetrieve()

        // NOW we wait for firstGet to actually finish
        _ = try await firstGet

        // Verify cache contains NEW credentials (not overwritten by OLD)
        let result = try await manager.getCredentials(forAccount: account)
        XCTAssertEqual(
            result,
            Credentials(apiKey: "newKey", apiSecret: "newSecret", passphrase: "newPass"),
            "Cache should retain newer credentials, not be overwritten by stale snapshot"
        )
    }

    /// Tests that an in-flight get() doesn't resurrect deleted credentials.
    func test_GetDoesNotResurrectCredentialsAfterDelete_withoutFix() async throws {
        let base = MockKeychainHelper()
        let account = "acc-delete"
        await base.setStorage(account: account, key: "oldKey", secret: "oldSecret", passphrase: nil)

        let helper = GatedKeychainHelper(base)
        let manager = CredentialManager(keychainHelper: helper)

        // Start get() - it will suspend with OLD snapshot
        async let firstGet: Credentials = try await manager.getCredentials(forAccount: account)
        await helper.waitUntilRetrieveStarted()

        // While suspended, delete credentials
        let status = await manager.deleteCredentials(forAccount: account)
        XCTAssertEqual(status, errSecSuccess)

        // Resume get() - it returns OLD snapshot
        await helper.releaseRetrieve()
        _ = try await firstGet

        await base.clear(account: account)

        // Verify credentials are deleted (not resurrected)
        do {
            _ = try await manager.getCredentials(forAccount: account)
            XCTFail("Expected to throw - credentials should be deleted, not resurrected")
        } catch {
            // Success
        }
    }
}
