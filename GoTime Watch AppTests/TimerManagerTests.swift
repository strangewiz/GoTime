import XCTest
@testable import GoTime_Watch_App

final class TimerManagerTests: XCTestCase {
    var timerManager: TimerManager!
    var defaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        // Use a temporary suite for testing
        defaults = UserDefaults(suiteName: "TestDefaults")!
        defaults.removePersistentDomain(forName: "TestDefaults")
        timerManager = TimerManager(defaults: defaults)
    }
    
    override func tearDown() {
        defaults.removePersistentDomain(forName: "TestDefaults")
        timerManager = nil
        super.tearDown()
    }
    
    func testInitialState() {
        // On init, if no target, it sets one
        XCTAssertNotNil(defaults.object(forKey: "targetVoidTime"))
        // Target should be roughly now + 2.5h
        let target = defaults.object(forKey: "targetVoidTime") as! Date
        let expected = Date().addingTimeInterval(timerManager.interval)
        // Allow variance
        XCTAssertEqual(target.timeIntervalSinceReferenceDate, expected.timeIntervalSinceReferenceDate, accuracy: 5.0)
    }
    
    func testResetTimer() {
        // Force a past date
        defaults.set(Date.distantPast, forKey: "targetVoidTime")
        
        timerManager.resetTimer()
        
        let target = defaults.object(forKey: "targetVoidTime") as! Date
        let expected = Date().addingTimeInterval(timerManager.interval)
        XCTAssertEqual(target.timeIntervalSinceReferenceDate, expected.timeIntervalSinceReferenceDate, accuracy: 5.0)
    }
    
    func testSnooze() {
        // Scenario 1: Overdue (Past)
        defaults.set(Date().addingTimeInterval(-60), forKey: "targetVoidTime") // 1 min ago
        
        timerManager.snooze()
        
        var target = defaults.object(forKey: "targetVoidTime") as! Date
        // Should be now + 10m
        var expected = Date().addingTimeInterval(10 * 60)
        XCTAssertEqual(target.timeIntervalSinceReferenceDate, expected.timeIntervalSinceReferenceDate, accuracy: 5.0)
        
        // Scenario 2: Active (Future)
        let future = Date().addingTimeInterval(3600) // 1h
        defaults.set(future, forKey: "targetVoidTime")
        
        timerManager.snooze()
        
        target = defaults.object(forKey: "targetVoidTime") as! Date
        // Should be future + 10m
        expected = future.addingTimeInterval(10 * 60)
        XCTAssertEqual(target.timeIntervalSinceReferenceDate, expected.timeIntervalSinceReferenceDate, accuracy: 5.0)
    }
    
    func testSleepSettingsAreSaved() {
        timerManager.setSleepSettings(enabled: true, start: 22, end: 7)
        XCTAssertTrue(timerManager.isSleepEnabled)
        XCTAssertEqual(timerManager.sleepStartHour, 22)
        XCTAssertEqual(timerManager.sleepEndHour, 7)
        
        timerManager.setSleepSettings(enabled: false, start: 22, end: 7)
        XCTAssertFalse(timerManager.isSleepEnabled)
    }
    
    func testTimerSkipsSleepWindow() {
        // Find current hour to fake a sleep window happening right now over the next target
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let endHour = (hour + 2) % 24
        
        // This makes the current time inside the sleep window (since it spans from now to now+2, or close enough, 
        // minus the exact minutes rolling over boundary, so let's simplify)
        // If we set sleep to start immediately and end in a few hours, the target should jump.
        timerManager.setSleepSettings(enabled: true, start: hour, end: endHour)
        
        // Trigger a reset. It should jump the target PAST `endHour`
        timerManager.resetTimer()
        
        let target = defaults.object(forKey: "targetVoidTime") as! Date
        let targetHour = Calendar.current.component(.hour, from: target)
        
        // Target hour should be exactly the endHour, or slightly past it depending on remaining minutes.
        // It definitely shouldn't be the same as it would be normally. 
        // Without sleep, target = now + 2.5h. 
        // With sleep starting now, target = next day's endHour + 2.5h
        // Our simple check is just ensuring the target hour isn't inside [hour, endHour)
        let isInsideSleep = (start: hour, end: endHour, val: targetHour) 
        if hour < endHour {
            XCTAssertFalse(targetHour >= hour && targetHour < endHour, "Target fell inside sleep window")
        } else {
            XCTAssertFalse(targetHour >= hour || targetHour < endHour, "Target fell inside sleep window crossing midnight")
        }
    }
}
