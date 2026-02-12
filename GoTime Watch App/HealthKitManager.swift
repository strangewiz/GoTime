import Foundation
import HealthKit
import WidgetKit

struct LogEntry: Identifiable {
    let id = UUID()
    let type: LogType
    let date: Date
    let metadata: String? // e.g. "Type 4"
    
    enum LogType {
        case pee
        case poop
        case miralax
    }
}

class HealthKitManager {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    // Identifiers using raw values to ensure compilation across SDK versions
    let bowelMovementID = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierBowelMovement")
    let intermittentVoidingID = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierIntermittentVoiding")
    let crampsID = HKCategoryTypeIdentifier.abdominalCramps
    
    // Types to Write
    var shareTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = []
        
        if let bowelMovement = HKObjectType.categoryType(forIdentifier: bowelMovementID) {
            types.insert(bowelMovement)
        }
        
        if let intermittentVoiding = HKObjectType.categoryType(forIdentifier: intermittentVoidingID) {
            types.insert(intermittentVoiding)
        } else if let cramps = HKObjectType.categoryType(forIdentifier: crampsID) {
            types.insert(cramps)
        }
        
        return types
    }
    
    // Request Authorization
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        healthStore.requestAuthorization(toShare: shareTypes, read: shareTypes) { success, error in
            if let error = error {
                print("HealthKit Auth Error: \(error.localizedDescription)")
            }
        }
    }
    
    // Log Pee
    func logPee() {
        var type = HKObjectType.categoryType(forIdentifier: intermittentVoidingID)
        
        if type == nil {
             type = HKObjectType.categoryType(forIdentifier: crampsID)
        }
        
        guard let finalType = type else { return }
        
        let sample = HKCategorySample(type: finalType, value: 0, start: Date(), end: Date(), metadata: ["Event": "Voiding"])
        
        healthStore.save(sample) { success, error in
            if let error = error {
                print("Error saving pee: \(error.localizedDescription)")
            }
        }
    }
    
    // Log Poop
    func logPoop(bristolScore: Int) {
        // Try standard type first
        var type = HKObjectType.categoryType(forIdentifier: bowelMovementID)
        var usedFallback = false
        
        if type == nil {
            print("DEBUG: BowelMovement Type missing, using Fallback (Cramps)")
            type = HKObjectType.categoryType(forIdentifier: crampsID)
            usedFallback = true
        }
        
        guard let finalType = type else { return }
        
        // Metadata
        var metadata: [String: Any] = [
            "HKBristolStoolScale": bristolScore
        ]
        
        if usedFallback {
            metadata["Event"] = "PoopFallback"
        }
        
        let sample = HKCategorySample(type: finalType, value: 0, start: Date(), end: Date(), metadata: metadata)
        
        healthStore.save(sample) { success, error in
            if let error = error {
                print("Error saving poop: \(error.localizedDescription)")
            } else {
                print("Poop saved successfully (Fallback: \(usedFallback))")
            }
        }
    }
    
    // Log Miralax
    func logMiralax() {
        guard let type = HKObjectType.categoryType(forIdentifier: crampsID) else { return }
        
        let metadata: [String: Any] = [
            "Medication": "Miralax",
            "Dose": "Daily"
        ]
        
        let sample = HKCategorySample(type: type, value: 0, start: Date(), end: Date(), metadata: metadata)
        
        healthStore.save(sample) { success, error in
            if let error = error {
                print("Error saving miralax: \(error.localizedDescription)")
            }
        }
    }
    
    // Fetch History
    func fetchHistory(completion: @escaping ([LogEntry]) -> Void) {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        var logs: [LogEntry] = []
        let group = DispatchGroup()
        
        // Debug
        let poopType = HKObjectType.categoryType(forIdentifier: bowelMovementID)
        
        // 1. Fetch Standard Poop (if available)
        if let type = poopType {
            group.enter()
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                if let samples = samples as? [HKCategorySample] {
                    for sample in samples {
                        let score = sample.metadata?["HKBristolStoolScale"] as? Int
                        logs.append(LogEntry(type: .poop, date: sample.startDate, metadata: score != nil ? "Type \(score!)" : nil))
                    }
                }
                group.leave()
            }
            healthStore.execute(query)
        }
        
        // 2. Fetch Vee/Miralax/FallbackPoop (using crampsID / voidingID)
        let otherTypes = [intermittentVoidingID, crampsID]
        for id in otherTypes {
            guard let type = HKObjectType.categoryType(forIdentifier: id) else { continue }
            group.enter()
            
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                if let samples = samples as? [HKCategorySample] {
                    for sample in samples {
                        let meta = sample.metadata ?? [:]
                        
                        // Detect Type
                        if let score = meta["HKBristolStoolScale"] as? Int {
                             // This is a Fallback Poop
                             logs.append(LogEntry(type: .poop, date: sample.startDate, metadata: "Type \(score) (F)"))
                        } else if meta["Medication"] as? String == "Miralax" {
                            logs.append(LogEntry(type: .miralax, date: sample.startDate, metadata: "Daily Dose"))
                        } else {
                            // Assume Pee (Voiding)
                            logs.append(LogEntry(type: .pee, date: sample.startDate, metadata: nil))
                        }
                    }
                }
                group.leave()
            }
            healthStore.execute(query)
        }
        
        group.notify(queue: .main) {
            // Deduplicate logic if needed (e.g. if we fetch crampsID twice via different loops? No, distinct queries).
            // But we might fetch crampsID in loop 2 which contains Miralax AND FallbackPoop. Logic handles it.
            
            logs.sort { $0.date > $1.date }
            // Unique by ID? LogEntry creates new ID. Unique by date/type?
            // For now assume okay.
            completion(logs)
        }
    }
}
