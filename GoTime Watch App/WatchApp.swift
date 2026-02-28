import SwiftUI

import UserNotifications

import SwiftUI
import WatchKit
import UserNotifications

@main
struct WatchApp: App {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    requestNotificationPermission()
                }
        }
        .backgroundTask(.appRefresh("com.justinsc.GoTime.refresh")) { context in
            // Handle new SwiftUI background task style if preferred, or rely on Delegate
            // For now, we will use the Delegate approach for broader compatibility/control
            // but this modifier is good practice in newer watchOS.
            // However, since we are implementing the Delegate, we will handle it there.
            // This block is just a placeholder to show intent or future migration.
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
}

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Background Refresh Task
                print("Handling Background Refresh Task")
                
                Task { @MainActor in
                    // Attempt to sync pending logs
                    await CloudKitManager.shared.syncPendingLogs()
                    
                    // Schedule next refresh (e.g., in 2 hours)
                    scheduleNextBackgroundRefresh()
                    
                    // Mark task as completed
                    backgroundTask.setTaskCompletedWithSnapshot(false)
                }
                
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
                
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                connectivityTask.setTaskCompletedWithSnapshot(false)
                
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                urlSessionTask.setTaskCompletedWithSnapshot(false)
                
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
                
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
                
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func scheduleNextBackgroundRefresh() {
        let targetDate = Date().addingTimeInterval(2 * 60 * 60) // 2 hours
        
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: targetDate, userInfo: nil) { error in
            if let error = error {
                print("Error scheduling background refresh: \(error.localizedDescription)")
            } else {
                print("Scheduled next background refresh for \(targetDate)")
            }
        }
    }
    
    // Schedule the first refresh when the app launches or enters foreground
    func applicationDidFinishLaunching() {
        print("App Launched - Scheduling Background Refresh")
        scheduleNextBackgroundRefresh()
    }
    
    func applicationDidBecomeActive() {
        // Optionally re-schedule or ensure one is scheduled
        Task {
            await CloudKitManager.shared.syncPendingLogs()
        }
    }
}
