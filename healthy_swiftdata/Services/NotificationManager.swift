//
//  NotificationManager.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 25/12/2025.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {}
    
    // Request notification permissions
    func requestAuthorization() async throws -> Bool {
        return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    // Schedule a notification for timer completion
    func scheduleTimerCompletionNotification(
        at date: Date,
        exerciseName: String,
        setNumber: Int
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "\(exerciseName) - Set \(setNumber)"
        content.sound = .default
        content.categoryIdentifier = "TIMER_COMPLETE"
        
        // Add user info for deep linking
        content.userInfo = [
            "type": "timer_complete",
            "exerciseName": exerciseName,
            "setNumber": setNumber
        ]
        
        // Create trigger for specific date
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create request with unique identifier
        let identifier = "rest_timer_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Cancel all timer notifications
    func cancelTimerNotifications() {
        // Remove all pending notifications that start with "rest_timer_"
        notificationCenter.getPendingNotificationRequests { requests in
            let timerIdentifiers = requests
                .filter { $0.identifier.hasPrefix("rest_timer_") }
                .map { $0.identifier }
            if !timerIdentifiers.isEmpty {
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: timerIdentifiers)
            }
        }
    }
    
    // Cancel a specific notification by identifier
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

