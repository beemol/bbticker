//
//  IAPProductID.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 24/06/2026.
//

import Foundation

enum IAPProductID {
    static let proUnlockSuffix = "pro.unlock"
    
    /// Product ID for app or test host
    static var forCurrentBundle: String {
        getBundleIdentifier() + "." + proUnlockSuffix
    }
    
    /// Fixed ID used in Products.storekit and MAS builds.
    static let masProUnlock = "com.alehfiodarau.bbticker.pro.unlock"
}
