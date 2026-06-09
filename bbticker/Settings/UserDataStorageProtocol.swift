//
//  UserDataStorageProtocol.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 30/09/2025.
//

import Foundation

protocol UserDataStorageProtocol {
    func save(key: String, value: Any)
    func value(forKey: String) -> Any?
}

struct UserDefaultsStorage: UserDataStorageProtocol {
    func save(key: String, value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    func value(forKey: String) -> Any? {
        UserDefaults.standard.object(forKey: forKey)
    }
}
