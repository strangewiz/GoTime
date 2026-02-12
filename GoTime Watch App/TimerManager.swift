import Foundation
import Combine
import WidgetKit

class TimerManager: ObservableObject {
    @Published var timeString: String = "2:30:00"
    @Published var progress: Double = 1.0 // 0.0 to 1.0
    @Published var isOverdue: Bool = false
    
    private var timer: Timer?
    private let defaults: UserDefaults
    private let targetKey = "targetVoidTime"
    
    // Constants
    let interval: TimeInterval = 2.5 * 60 * 60 // 2.5 hours
    let snoozeInterval: TimeInterval = 10 * 60 // 10 minutes
    
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
        let newTarget = Date().addingTimeInterval(interval)
        defaults.set(newTarget, forKey: targetKey)
        reloadComplications()
        updateState()
    }
    
    func snooze() {
        // Add 10 minutes to current time? Or to the target?
        // "Snooze: A 10-minute delay option"
        // Typically extends current target by 10 mins OR if overdue, sets to Now + 10 mins.
        
        let target = getTargetDate()
        var newTarget: Date
        
        if Date() > target {
            // Already overdue, set to 10 mins from now
            newTarget = Date().addingTimeInterval(snoozeInterval)
        } else {
            // Still running, add 10 mins to existing deadline
            newTarget = target.addingTimeInterval(snoozeInterval)
        }
        
        defaults.set(newTarget, forKey: targetKey)
        reloadComplications()
        updateState()
    }
    
    private func getTargetDate() -> Date {
        if let date = defaults.object(forKey: targetKey) as? Date {
            return date
        }
        // If nil, set default
        let newTarget = Date().addingTimeInterval(interval)
        defaults.set(newTarget, forKey: targetKey)
        return newTarget
    }
    
    private func updateState() {
        let target = getTargetDate()
        let now = Date()
        let remaining = target.timeIntervalSince(now)
        
        if remaining <= 0 {
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
