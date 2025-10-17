//
//  Haptics.swift
//  Unknown Detective
//
//  Lightweight haptics helper. Safe no-op on platforms without UIKit.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

enum Haptics {
    private static var isEnabled: Bool {
        // Default: enabled
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    static func success() {
        #if canImport(UIKit)
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    static func warning() {
        #if canImport(UIKit)
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #endif
    }

    static func error() {
        #if canImport(UIKit)
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        #endif
    }

    static func light() {
        #if canImport(UIKit)
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}
