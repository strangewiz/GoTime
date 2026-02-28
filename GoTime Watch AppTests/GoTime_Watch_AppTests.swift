//
//  GoTime_Watch_AppTests.swift
//  GoTime Watch AppTests
//
//  Created by Justin Cohen on 2/12/26.
//

import XCTest
@testable import GoTime_Watch_App

final class GoTime_Watch_AppTests: XCTestCase {

    override func setUpWithError() throws {
        // Clear pending logs before each test
        UserDefaults.standard.removeObject(forKey: "pending_cloudkit_logs")
    }

    override func tearDownWithError() throws {
        // Clear pending logs after each test
        UserDefaults.standard.removeObject(forKey: "pending_cloudkit_logs")
    }

    func testCloudKitManagerQueuesLogs() throws {
        let manager = CloudKitManager.shared
        
        let initialData = UserDefaults.standard.data(forKey: "pending_cloudkit_logs")
        let initialLogs = initialData.flatMap { try? JSONDecoder().decode([LogEntry].self, from: $0) } ?? []
        XCTAssertTrue(initialLogs.isEmpty, "Pending logs should be empty initially")
        
        // Save a mock log
        let log = LogEntry(id: UUID(), type: .pee, date: Date(), extraData: nil)
        manager.save(log: log)
        
        // Wait a small amount for synchronous part of save to finish
        // the addition to pendingLogs is synchronous before the Task starts.
        
        let newData = UserDefaults.standard.data(forKey: "pending_cloudkit_logs")
        let newLogs = newData.flatMap { try? JSONDecoder().decode([LogEntry].self, from: $0) } ?? []
        
        XCTAssertEqual(newLogs.count, 1, "There should be one pending log")
        XCTAssertEqual(newLogs.first?.id, log.id, "The queued log should match the saved log")
    }
    
    func testCloudKitManagerQueuesMultipleLogs() throws {
        let manager = CloudKitManager.shared
        
        let log1 = LogEntry(id: UUID(), type: .pee, date: Date(), extraData: nil)
        let log2 = LogEntry(id: UUID(), type: .poop, date: Date(), extraData: nil)
        
        manager.save(log: log1)
        manager.save(log: log2)
        
        let newData = UserDefaults.standard.data(forKey: "pending_cloudkit_logs")
        let newLogs = newData.flatMap { try? JSONDecoder().decode([LogEntry].self, from: $0) } ?? []
        
        XCTAssertEqual(newLogs.count, 2, "There should be two pending logs queued")
        XCTAssertEqual(newLogs.first?.id, log1.id)
        XCTAssertEqual(newLogs.last?.id, log2.id)
    }

}
