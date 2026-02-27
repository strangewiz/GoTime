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
    
    init() {
        // Initialize Zone
        createZoneIfNeeded()
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
        // 1. Create Record ID in the Custom Zone
        let recordID = CKRecord.ID(recordName: log.id.uuidString, zoneID: zoneId)
        let record = CKRecord(recordType: "PottyEvent", recordID: recordID)
        
        // 2. Set Fields
        record["type"] = log.type.rawValue
        record["date"] = log.date
        if let extras = log.extraData {
            record["extraData"] = extras
        }
        
        // 3. Save
        container.privateCloudDatabase.save(record) { record, error in
            if let error = error {
                print("CloudKit Save Error: \(error.localizedDescription)")
                DispatchQueue.main.async { self.lastError = error.localizedDescription }
            } else {
                print("Saved to CloudKit")
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
