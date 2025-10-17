//
//  AppPreferences.swift
//  Unknown Detective
//
//  Simple convenience for storing small app-level preferences.
//

import Foundation

enum AppPreferences {
    private static let lastCaseTypeKey = "AppPreferences.lastCaseType"
    private static let notificationsEnabledKey = "AppPreferences.notificationsEnabled"

    static var lastCaseType: CaseType? {
        get {
            guard let raw = UserDefaults.standard.string(forKey: lastCaseTypeKey) else { return nil }
            return CaseType(rawValue: raw)
        }
        set {
            if let type = newValue {
                UserDefaults.standard.set(type.rawValue, forKey: lastCaseTypeKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastCaseTypeKey)
            }
        }
    }

    static var notificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: notificationsEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: notificationsEnabledKey) }
    }
}
