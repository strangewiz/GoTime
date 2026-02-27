import Foundation

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let type: LogType
    let date: Date
    let extraData: String? // e.g. "Type 4"
    
    enum LogType: String, Codable {
        case pee
        case poop
        case miralax
    }
}

class HistoryManager {
    static let shared = HistoryManager()
    
    private let defaults = UserDefaults(suiteName: "group.com.justinsc.GoTime") ?? .standard
    private let storageKey = "history_logs"
    
    // Core Add Function
    func addEntry(type: LogEntry.LogType, extraData: String? = nil) {
        var logs = getLogs()
        let newEntry = LogEntry(id: UUID(), type: type, date: Date(), extraData: extraData)
        logs.append(newEntry)
        saveLogs(logs)
        
        // Sync to HealthKit (Proxy) - DISABLED
        // HealthKitManager.shared.saveLog(type: type, extraData: extraData)
        
        // Sync to CloudKit
        CloudKitManager.shared.save(log: newEntry)
    }
    
    // Core Fetch Function
    func getLogs() -> [LogEntry] {
        guard let data = defaults.data(forKey: storageKey) else { return [] }
        if let decoded = try? JSONDecoder().decode([LogEntry].self, from: data) {
            // Sort by date descending
            return decoded.sorted { $0.date > $1.date }
        }
        return []
    }
    
    // Private Save
    private func saveLogs(_ logs: [LogEntry]) {
        if let encoded = try? JSONEncoder().encode(logs) {
            defaults.set(encoded, forKey: storageKey)
        }
    }
    
    // Helper for 7-Day Filter
    func getRecentLogs() -> [LogEntry] {
        let logs = getLogs()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return logs.filter { $0.date >= sevenDaysAgo }
    }
    
    // Clear Data
    func clearAllData() {
        defaults.removeObject(forKey: storageKey)
        CloudKitManager.shared.deleteAllCloudKitData()
    }
}
