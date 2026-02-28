import Foundation
import CloudKit
import Combine
import SwiftUI

class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    // Config
    // NOTE: User must replace this if using a custom container, but .default() works if the app's bundle ID matches the container.
    // For specific container: CKContainer(identifier: "iCloud.com.justinsc.GoTime.watchkitapp")
    let container = CKContainer.default()
    
    private let zoneId = CKRecordZone.ID(zoneName: "GoTimeZone", ownerName: CKCurrentUserDefaultName)
    
    @Published var share: CKShare?
    @Published var isSaving = false
    @Published var lastError: String?
    
    // Offline Sync Queue
    private let pendingLogsKey = "pending_cloudkit_logs"
    
    private var pendingLogs: [LogEntry] {
        get {
            guard let data = UserDefaults.standard.data(forKey: pendingLogsKey) else { return [] }
            return (try? JSONDecoder().decode([LogEntry].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: pendingLogsKey)
            }
        }
    }
    
    init() {
        // Initialize Zone
        createZoneIfNeeded()
        // Retry any pending uploads
        Task {
            await syncPendingLogs()
        }
    }
    
    // MARK: - Zone Management
    private func createZoneIfNeeded() {
        let newZone = CKRecordZone(zoneID: zoneId)
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [newZone], recordZoneIDsToDelete: nil)
        
        operation.modifyRecordZonesResultBlock = { result in
            switch result {
            case .success:
                print("CloudKit Zone Created/Verified")
            case .failure(let error):
                print("Error creating zone: \(error.localizedDescription)")
            }
        }
        
        container.privateCloudDatabase.add(operation)
    }
    
    // MARK: - Saving Records
    func save(log: LogEntry) {
        // Add to pending queue
        var logs = pendingLogs
        logs.append(log)
        pendingLogs = logs
        
        Task {
            await syncPendingLogs()
        }
    }
    
    func syncPendingLogs() async {
        // Prevent concurrent syncs
        guard !isSaving else { return }
        
        // Check if there are logs to sync
        let logsToSync = pendingLogs
        guard !logsToSync.isEmpty else { return }
        
        await MainActor.run { isSaving = true }
        
        defer {
            Task { @MainActor in isSaving = false }
        }
        
        // Convert to CKRecords
        let records = logsToSync.map { log -> CKRecord in
            let recordID = CKRecord.ID(recordName: log.id.uuidString, zoneID: zoneId)
            let record = CKRecord(recordType: "PottyEvent", recordID: recordID)
            record["type"] = log.type.rawValue
            record["date"] = log.date
            if let extras = log.extraData {
                record["extraData"] = extras
            }
            return record
        }
        
        do {
            let (saveResults, _) = try await container.privateCloudDatabase.modifyRecords(saving: records, deleting: [])
            
            await MainActor.run {
                // Collect successful record IDs
                var successfulRecordIDs: [CKRecord.ID] = []
                for (recordID, result) in saveResults {
                    switch result {
                    case .success:
                        successfulRecordIDs.append(recordID)
                    case .failure(let error):
                        print("Error saving record \(recordID): \(error.localizedDescription)")
                    }
                }
                
                // Remove successful logs from pending queue
                if !successfulRecordIDs.isEmpty {
                    var currentPending = self.pendingLogs
                    // Map recordIDs to UUIDs
                    let savedUUIDs = successfulRecordIDs.compactMap { UUID(uuidString: $0.recordName) }
                    currentPending.removeAll { log in savedUUIDs.contains(log.id) }
                    self.pendingLogs = currentPending
                    print("Synced \(successfulRecordIDs.count) logs to CloudKit. Remaining: \(currentPending.count)")
                }
                
                print("CloudKit Sync finished successfully.")
            }
            
            // Check if more logs are pending (added during sync) and recurse if we made progress
            // Note: In async context, we can just call it again.
            // Check safely on main actor or just read from UserDefaults (which is thread safe)
            if !pendingLogs.isEmpty {
                 await syncPendingLogs()
            }
            
        } catch {
            await MainActor.run {
                print("CloudKit Sync Error: \(error.localizedDescription)")
                self.lastError = error.localizedDescription
            }
        }
    }
    
    // MARK: - Sharing
    func fetchOrCreateShare() {
        // Check if share exists for the zone
        // We actually share the entire ZONE.
        
        let shareID = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zoneId)
        
        container.privateCloudDatabase.fetch(withRecordID: shareID) { record, error in
            if let existingShare = record as? CKShare {
                DispatchQueue.main.async {
                    self.share = existingShare
                }
            } else {
                // Create new share
                self.createNewShare()
            }
        }
    }
    
    private func createNewShare() {
        let share = CKShare(recordZoneID: zoneId)
        share.publicPermission = .readOnly // Parent can read
        share[CKShare.SystemFieldKey.title] = "GoTime Bathroom Logs" as CKRecordValue
        share[CKShare.SystemFieldKey.shareType] = "com.justinsc.GoTime.watchkitapp.logs" as CKRecordValue
        
        let operation = CKModifyRecordsOperation(recordsToSave: [share], recordIDsToDelete: nil)
        
        operation.perRecordSaveBlock = { recordID, result in
            switch result {
            case .success(let record):
                if let savedShare = record as? CKShare {
                    print("Share saved successfully with URL: \(savedShare.url?.absoluteString ?? "none")")
                    DispatchQueue.main.async {
                        self.share = savedShare
                    }
                }
            case .failure(let error):
                print("Error saving share record: \(error.localizedDescription)")
                DispatchQueue.main.async { self.lastError = error.localizedDescription }
            }
        }
        
        operation.modifyRecordsResultBlock = { result in
            switch result {
            case .success:
                print("Share modify operation finished")
            case .failure(let error):
                print("Error in share operation: \(error.localizedDescription)")
                DispatchQueue.main.async { self.lastError = error.localizedDescription }
            }
        }
        
        container.privateCloudDatabase.add(operation)
    }
    
    // MARK: - Clear Data
    func deleteAllCloudKitData(completion: @escaping (Bool) -> Void = { _ in }) {
        let query = CKQuery(recordType: "PottyEvent", predicate: NSPredicate(value: true))
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.zoneID = zoneId
        
        var recordIDsToDelete: [CKRecord.ID] = []
        
        queryOperation.recordMatchedBlock = { recordID, result in
            if case .success = result {
                recordIDsToDelete.append(recordID)
            }
        }
        
        queryOperation.queryResultBlock = { result in
            switch result {
            case .success:
                guard !recordIDsToDelete.isEmpty else {
                    completion(true)
                    return
                }
                
                let deleteOp = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsToDelete)
                deleteOp.modifyRecordsResultBlock = { modifyResult in
                    switch modifyResult {
                    case .success:
                        print("Successfully cleared all CloudKit records.")
                        completion(true)
                    case .failure(let error):
                        print("Failed to delete CloudKit records: \(error.localizedDescription)")
                        completion(false)
                    }
                }
                self.container.privateCloudDatabase.add(deleteOp)
                
            case .failure(let error):
                print("Error finding records to delete: \(error.localizedDescription)")
                completion(false)
            }
        }
        
        container.privateCloudDatabase.add(queryOperation)
    }
}
