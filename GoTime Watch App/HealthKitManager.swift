import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    // Valid Identifiers
    let crampsID = HKCategoryTypeIdentifier.abdominalCramps
    
    // Request Authorization
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        var shareTypes: Set<HKSampleType> = []
        if let cramps = HKObjectType.categoryType(forIdentifier: crampsID) {
            shareTypes.insert(cramps)
        }
        
        healthStore.requestAuthorization(toShare: shareTypes, read: shareTypes) { success, error in
            if let error = error {
                print("HealthKit Auth Error: \(error.localizedDescription)")
            }
        }
    }
    
    // Universal Log to HealthKit (Proxy)
    func saveLog(type: LogEntry.LogType, extraData: String?) {
        guard let sampleType = HKObjectType.categoryType(forIdentifier: crampsID) else { return }
        
        var metadata: [String: Any] = [:]
        
        switch type {
        case .pee:
            metadata["Event"] = "Pee (Voiding)"
        case .poop:
            metadata["Event"] = "Poop (Bowel Movement)"
            if let data = extraData {
                metadata["BristolScale"] = data
            }
        case .miralax:
            metadata["Event"] = "Medication (Miralax)"
        }
        
        let sample = HKCategorySample(type: sampleType, value: 0, start: Date(), end: Date(), metadata: metadata)
        
        healthStore.save(sample) { success, error in
            if let error = error {
                print("Error saving to HealthKit: \(error.localizedDescription)")
            } else {
                print("Successfully syncd \(type) to HealthKit as Cramps")
            }
        }
    }
}
