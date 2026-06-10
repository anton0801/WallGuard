import Foundation
import UIKit
import UserNotifications

protocol Watchman {
    func raiseQuery() async -> Bool
    func wirePushBeacon()
}

final class NotificationWatchman: Watchman {
    
    func raiseQuery() async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let sentry = LonewolfGate()
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, error in
                if let error = error {
                    print("\(BastionIdiom.logShield) Watchman error: \(error)")
                }
                DispatchQueue.main.async {
                    guard sentry.tryPass() else { return }
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func wirePushBeacon() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

final class LonewolfGate {
    private var passed = false
    private let lock = NSLock()
    
    func tryPass() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !passed else { return false }
        passed = true
        return true
    }
}
