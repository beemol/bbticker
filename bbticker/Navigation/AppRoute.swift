//
//  SettingsSection.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 9/29/26.
//


import Foundation

enum SettingsSection: String, Hashable, Sendable {
    case apiCredentials
}

enum AppRoute: Hashable, Sendable {
    case settings(section: SettingsSection?)
}
