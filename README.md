# GoTime - Pediatric Voiding & Bowel Tracker

GoTime is a specialized watchOS application designed to help track intermittent voiding and bowel movements for pediatric patients. It provides a simple, child-friendly interface for logging events and a recurring countdown timer to encourage regular bathroom breaks.

## Features

### 🕒 Recurring Timer
- **2.5-Hour Countdown**: Automatically resets after logging a "Pee" event.
- **Snooze**: 10-minute snooze option for when immediate access isn't possible.
- **Smart Logic**: Automatically adjusts targets based on the last logged event.

### 📝 Comprehensive Logging (Dual Storage)
- **Local History**: Logs are stored securely on the Watch for immediate viewing by the child/wearer.
- **Parent Monitoring**: Logs are *also* synced to Apple Health (on the paired iPhone) as **"Abdominal Cramps"** events. This allows parents to track frequency and timing remotely via their own Health App.
- **Detailed Metadata**: Each HealthKit entry includes tags for "Pee", "Poop", or "Meds".

### ⌚ Complication (Widget)
- **At-a-Glance Status**: See exactly how much time is left until the next check-in directly on the watch face.
- **Custom Formatting**: Displays clear "2h 30m" or "15m" text updates (no seconds) for readability.
- **Instant Sync**: Uses App Groups to synchronize timer state between the App and Widget instantly.

### 📊 History
- **7-Day History**: View a color-coded log of the last week's events directly on the watch.

## Technical Details

- **Platform**: watchOS 10+
- **Technologies**: SwiftUI, HealthKit, WidgetKit, Combine.
- **Data Persistence**: `UserDefaults` (shared via App Groups) + HealthKit Proxy.

## Setup Requirements

### App Groups
To ensure the Complication syncs correctly and History is shared, you must configure **App Groups** in Xcode:
1.  Select the Project -> **GoTime Watch App** Target -> Signing & Capabilities -> + Capability -> **App Groups**.
2.  Add/Select `group.com.justinsc.GoTime`.
3.  Repeat for the **GoTimerWidgetExtension** Target.

### HealthKit Permissions
The app writes data to the **"Abdominal Cramps"** category in HealthKit. Ensure Write access is granted upon first launch to enable Parent Monitoring.

### CloudKit Permissions & Dashboard
Enable the **iCloud (CloudKit)** capability in Xcode for the Watch App target.

**Web Dashboard Setup:**
1.  Navigate to the `dashboard/` folder.
2.  Rename `config.example.js` to `config.js`.
3.  Open `config.js` and insert your **CloudKit API Token** and **Container ID**.
4.  Open `index.html` in any browser to view shared logs remotely.

## Installation

1.  Clone the repository.
2.  Open `GoTime.xcodeproj` in Xcode.
3.  Ensure your Development Team is selected for signing.
4.  Run on Apple Watch (Series 4 or later recommended) or Simulator.
