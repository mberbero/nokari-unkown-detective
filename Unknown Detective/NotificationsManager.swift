//
//  NotificationsManager.swift
//  Unknown Detective
//
//  Manages local notifications for daily bonus/refill reminders.
//

import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationsManager: ObservableObject {
    static let shared = NotificationsManager()
    private init() {}

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            return false
        }
    }

    func scheduleDailyReminder(at date: Date) {
        let center = UNUserNotificationCenter.current()
        // Remove previous reminders first
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderId])

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Günlük hatırlatma", comment: "Daily reminder title")
        content.body = NSLocalizedString("Günlük bonusun hazır. Yeni vakalara dalmak için geri dön!", comment: "Daily reminder body")
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: Self.dailyReminderId, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderId])
    }

    private static let dailyReminderId = "com.unknowndetective.dailyReminder"
}
