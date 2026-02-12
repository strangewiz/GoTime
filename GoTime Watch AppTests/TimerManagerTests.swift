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
}
