import Foundation
import Combine
import WidgetKit
import UserNotifications
import WatchKit

class TimerManager: ObservableObject {
    @Published var timeString: String = "2:30:00"
    @Published var progress: Double = 1.0 // 0.0 to 1.0
    @Published var isOverdue: Bool = false
    
    private var timer: Timer?
    private let defaults: UserDefaults
    private let targetKey = "targetVoidTime"
    
    // Configuration
    var interval: TimeInterval {
        let saved = defaults.double(forKey: "customTimerInterval")
        return saved > 0 ? saved : (2.5 * 60 * 60)
    }
    let snoozeInterval: TimeInterval = 10 * 60 // 10 minutes
    
    // Sleep Configuration
    var isSleepEnabled: Bool {
        defaults.object(forKey: "isSleepEnabled") == nil ? true : defaults.bool(forKey: "isSleepEnabled")
    }
    var sleepStartHour: Int {
        defaults.object(forKey: "sleepStartHour") == nil ? 20 : defaults.integer(forKey: "sleepStartHour")
    }
    var sleepEndHour: Int {
        defaults.object(forKey: "sleepEndHour") == nil ? 8 : defaults.integer(forKey: "sleepEndHour")
    }
    
    func setInterval(minutes: Double) {
        defaults.set(minutes * 60, forKey: "customTimerInterval")
        resetTimer()
    }
    
    func setSleepSettings(enabled: Bool, start: Int, end: Int) {
        defaults.set(enabled, forKey: "isSleepEnabled")
        defaults.set(start, forKey: "sleepStartHour")
        defaults.set(end, forKey: "sleepEndHour")
        resetTimer()
    }
    
    init(defaults: UserDefaults = UserDefaults(suiteName: "group.com.justinsc.GoTime") ?? .standard) {
        self.defaults = defaults
        startTimer()
    }
    
    func startTimer() {
        updateState()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateState()
        }
    }
    
    func resetTimer() {
        let newTarget = addWorkingTime(interval, to: Date())
        defaults.set(newTarget, forKey: targetKey)
        scheduleNotification(for: newTarget)
        reloadComplications()
        updateState()
    }
    
    func snooze() {
        let target = getTargetDate()
        var newTarget: Date
        
        if Date() > target {
            // Already overdue, set to 10 mins from now ignoring sleep if we want? Let's respect sleep.
            newTarget = addWorkingTime(snoozeInterval, to: Date())
        } else {
            // Still running, add 10 mins to existing deadline
            newTarget = addWorkingTime(snoozeInterval, to: target)
        }
        
        defaults.set(newTarget, forKey: targetKey)
        scheduleNotification(for: newTarget)
        reloadComplications()
        updateState()
    }
    
    // MARK: - Time Math
    private func addWorkingTime(_ duration: TimeInterval, to startDate: Date) -> Date {
        guard isSleepEnabled else {
            return startDate.addingTimeInterval(duration)
        }
        
        var current = startDate
        var remaining = duration
        let calendar = Calendar.current
        let startHour = self.sleepStartHour
        let endHour = self.sleepEndHour

        if startHour == endHour { return startDate.addingTimeInterval(duration) }

        var iterations = 0
        while remaining > 0 && iterations < 1000 {
            iterations += 1
            let hour = calendar.component(.hour, from: current)
            
            var isSleeping = false
            if startHour < endHour {
                isSleeping = (hour >= startHour && hour < endHour)
            } else {
                isSleeping = (hour >= startHour || hour < endHour)
            }
            
            if isSleeping {
                var components = calendar.dateComponents([.year, .month, .day], from: current)
                components.hour = endHour
                components.minute = 0
                components.second = 0
                var nextWake = calendar.date(from: components)!
                if nextWake <= current {
                    nextWake = calendar.date(byAdding: .day, value: 1, to: nextWake)!
                }
                current = nextWake
            } else {
                var components = calendar.dateComponents([.year, .month, .day], from: current)
                components.hour = startHour
                components.minute = 0
                components.second = 0
                var nextSleep = calendar.date(from: components)!
                if nextSleep <= current {
                    nextSleep = calendar.date(byAdding: .day, value: 1, to: nextSleep)!
                }
                
                let timeToSleep = nextSleep.timeIntervalSince(current)
                if remaining <= timeToSleep {
                    current = current.addingTimeInterval(remaining)
                    remaining = 0
                } else {
                    current = nextSleep
                    remaining -= timeToSleep
                }
            }
        }
        return current
    }
    
    // MARK: - Notifications
    private func scheduleNotification(for targetDate: Date) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let timeInterval = targetDate.timeIntervalSince(Date())
        guard timeInterval > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "GoTime!"
        content.body = "It's time to try going to the bathroom."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully for \(targetDate)")
            }
        }
    }
    
    // MARK: - Handlers
    private func getTargetDate() -> Date {
        if let date = defaults.object(forKey: targetKey) as? Date {
            return date
        }
        let newTarget = addWorkingTime(interval, to: Date())
        defaults.set(newTarget, forKey: targetKey)
        return newTarget
    }
    
    private func updateState() {
        if isSleepEnabled {
            let hour = Calendar.current.component(.hour, from: Date())
            let start = sleepStartHour
            let end = sleepEndHour
            let sleeping = start < end ? (hour >= start && hour < end) : (hour >= start || hour < end)
            
            if sleeping && start != end {
                timeString = "Zzz..."
                progress = 1.0
                isOverdue = false
                return
            }
        }
        
        let target = getTargetDate()
        let now = Date()
        let remaining = target.timeIntervalSince(now)
        
        if remaining <= 0 {
            if !isOverdue {
                WKInterfaceDevice.current().play(.notification)
            }
            isOverdue = true
            timeString = "CHECK IN"
            progress = 0.0
        } else {
            isOverdue = false
            progress = remaining / interval
            
            let hours = Int(remaining) / 3600
            let minutes = Int(remaining) / 60 % 60
            let seconds = Int(remaining) % 60
            timeString = String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    private func reloadComplications() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
