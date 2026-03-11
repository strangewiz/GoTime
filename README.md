# GoTime - Pediatric Voiding & Bowel Tracker

GoTime is a specialized watchOS application designed to help track intermittent voiding and bowel movements for pediatric patients. It provides a simple, child-friendly interface for logging events and a recurring countdown timer to encourage regular bathroom breaks.

## Features

### 🕒 Customizable Recurring Timer
- **Adjustable Target**: Customize the countdown duration (default 2.5 hours). Automatically resets after logging a "Pee" event.
- **Snooze**: 10-minute snooze option for when immediate access isn't possible.
- **Sleep Mode**: Configure quiet hours (e.g., 8 PM to 8 AM) to pause the timer and disable notifications automatically overnight.

### 📳 Silent Notifications
- **Haptic Alerts**: Native watchOS notifications use haptics (vibration) in silent mode when the timer hits zero, ideal for school environments without audible disruptions.

### 📝 Comprehensive Logging (Triple Storage)
- **Local History**: Logs are stored securely on the Watch for immediate viewing by the child/wearer.
- **CloudKit Sync**: Logs are pushed to a private database and can be viewed via the Web Dashboard or shared with parents.
- **Offline Sync Queue**: Logs made while disconnected from the internet are securely queued and automatically uploaded to iCloud in the background once a connection is restored.
- **Privacy & Clearing**: In the Settings tab, you can clear all recorded local logs and remotely wipe CloudKit data simultaneously for perfect privacy.
- **Parent Monitoring (HealthKit)**: (Disabled) Logs can sync to Apple Health on the paired iPhone. This is currently disabled by default.

### ⌚ Complication (Widget)
- **At-a-Glance Status**: See exactly how much time is left until the next check-in directly on the watch face.
- **Smart Sleep Display**: The complication automatically switches to "Zzz..." during your configured sleep hours.
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

### HealthKit Permissions (Optional)
This app includes code to sync logs to Apple Health as "Abdominal Cramps" (proxy for generic events). This feature is currently **disabled** by default in the code but can be re-enabled by uncommenting the relevant lines in `HistoryManager.swift` and `GoTime Watch App.entitlements`.

### CloudKit Permissions & Dashboard
Enable the **iCloud (CloudKit)** capability in Xcode for the Watch App target.


**Web Dashboard Setup:**
1.  Navigate to the `dashboard/` folder.
2.  Open `index.html` in your web browser. Ensure the Environment dropdown (located in the footer) is set correctly (defaults to Production).
3.  Optional: If cloning your own fork, edit `index.html` to insert your own CloudKit API tokens.

**Admin Dashboard Setup:**
To manually correct or backfill missed logs on behalf of the child:
1. Navigate to `dashboard/admin.html` in your web browser.
2. **Important:** You must sign in using the **child's Apple ID**. Due to CloudKit Shared Database permissions, parents (who receive the read-only share link) cannot mutate records.
3. Once logged in as the child, you can use the form to add new logs or delete existing incorrect logs.

## Installation

1.  Clone the repository.
2.  Open `GoTime.xcodeproj` in Xcode.
3.  Ensure your Development Team is selected for signing.
4.  Run on Apple Watch (Series 4 or later recommended) or Simulator.
