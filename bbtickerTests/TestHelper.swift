//
//  TestHelper.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 04/11/2025.
//

import SwiftUI

@propertyWrapper
final class Atomic<Value>: @unchecked Sendable {
    private var value: Value
    private let lock = NSLock()

    init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    var wrappedValue: Value {
        get {
            lock.lock(); defer { lock.unlock() }
            return value
        }
        set {
            lock.lock(); defer { lock.unlock() }
            value = newValue
        }
    }
}

// Note: The @State shadowing approach is no longer valid.
// We now use @Observable classes for testable state management.

public enum TestHeap {

    // A key we use to store a value to mark we are running Unit Tests.
    static let unitTestKey = UUID().uuidString

    // storage for injections. we can access specific storage by its key
    // === From Docs:
    // Task local values cannot be set directly and must instead be bound using the scoped $storage.withValue() { ... } operation.
    // The value is only bound for the duration of that scope, and is available to any child tasks which are created within that scope.
    @TaskLocal
    private static var storage: [String: Atomic<Any>] = [:]

    // makes thread safe execution of give Any data, binding it to a Local storage
    static func execute(with storage: [String: Any],
                      operation: () async throws -> Void) async rethrows {
        
    // It executes the given operation inside a TaskLocal so that the operation
    // has transparent access to anything inside a storage defined by a key.
    // It copies the received storage into the TaskLocal storage.
        
    // Binds the task-local to the specific value for the duration of the asynchronous operation.
    // The value is available throughout the execution of the operation closure
    // If the value is a reference type, it will be retained for the duration of the operation closure.
    try await self.$storage.withValue(storage.mapValues { Atomic(wrappedValue: $0) },
                                      operation: operation)
    }

    // True if this function is called within the TaskLocal execution, False otherwise
    public static var isRunningUnitTest: Bool {
        guard let atomic = self.storage[self.unitTestKey],
              let value = atomic.wrappedValue as? Bool,
              value == true else { return false }
        return true
    }
}

public struct Injector: Sendable {
    
    @Atomic
    private(set) var storage: [String: Any] = [TestHeap.unitTestKey: true]

    public nonmutating func inject<T>(_ value: T, for key: String) {
        self.storage[key] = value
    }
}
