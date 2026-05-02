import Foundation
import UserNotifications

class ReminderService {
    static let shared = ReminderService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    func requestPermission() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    func scheduleWaterReminders(startHour: Int = 8, endHour: Int = 20, intervalHours: Int = 2) async {
        // Remove old water reminders first
        notificationCenter.removePendingNotificationRequests(withIdentifiers: waterReminderIDs(startHour: startHour, endHour: endHour, intervalHours: intervalHours))
        
        // Remove all existing water reminders by prefix
        let pending = await notificationCenter.pendingNotificationRequests()
        let waterIDs = pending.filter { $0.identifier.hasPrefix("water_reminder_") }.map { $0.identifier }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: waterIDs)
        
        let granted = await requestPermission()
        guard granted else { return }
        
        let messages = [
            "Đã đến giờ uống nước rồi! 💧",
            "Nhớ uống nước nhé! Cơ thể bạn cần nước 🥤",
            "Hydrate! Uống một ly nước nào 💦",
            "Bạn đã uống nước chưa? Uống ngay nhé! 🌊"
        ]
        
        var hour = startHour
        var index = 0
        while hour <= endHour {
            let content = UNMutableNotificationContent()
            content.title = "LiiO EatClean"
            content.body = messages[index % messages.count]
            content.sound = .default
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "water_reminder_\(hour)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Failed to schedule reminder at \(hour): \(error)")
            }
            
            hour += intervalHours
            index += 1
        }
    }
    
    func cancelAllWaterReminders() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let waterIDs = pending.filter { $0.identifier.hasPrefix("water_reminder_") }.map { $0.identifier }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: waterIDs)
    }
    
    private func waterReminderIDs(startHour: Int, endHour: Int, intervalHours: Int) -> [String] {
        var ids: [String] = []
        var hour = startHour
        while hour <= endHour {
            ids.append("water_reminder_\(hour)")
            hour += intervalHours
        }
        return ids
    }
    
    // Schedule meal logging reminders too
    func scheduleMealReminders() async {
        let granted = await requestPermission()
        guard granted else { return }
        
        let meals = [
            (hour: 7, title: "Bữa sáng", body: "Đừng quên log bữa sáng nhé! 🌅"),
            (hour: 12, title: "Bữa trưa", body: "Đã trưa rồi! Log bữa trưa nào 🍜"),
            (hour: 19, title: "Bữa tối", body: "Log bữa tối để theo dõi calo hôm nay 🌙")
        ]
        
        for meal in meals {
            let content = UNMutableNotificationContent()
            content.title = "LiiO EatClean — \(meal.title)"
            content.body = meal.body
            content.sound = .default
            
            var dateComponents = DateComponents()
            dateComponents.hour = meal.hour
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "meal_reminder_\(meal.hour)",
                content: content,
                trigger: trigger
            )
            
            try? await notificationCenter.add(request)
        }
    }
}
