# GoTime - Pediatric Voiding & Bowel Tracker

GoTime is a specialized watchOS application designed to help track intermittent voiding and bowel movements for pediatric patients. It provides a simple, child-friendly interface for logging events, a recurring countdown timer to encourage regular bathroom breaks, and HealthKit integration for long-term tracking.

## Features

### 🕒 Recurring Timer
- **2.5-Hour Countdown**: Automatically resets after logging a "Pee" event.
- **Snooze**: 10-minute snooze option for when immediate access isn't possible.
- **Smart Logic**: Automatically adjusts targets based on the last logged event.

### 📝 Comprehensive Logging
- **Pee (Voiding)**: Quick one-tap logging with confirmation.
- **Poop (Bowel Movements)**: Integrated **Bristol Stool Scale** with custom, child-friendly visual icons for all 7 types.
- **Medications**: Track daily Miralax intake.

### ⌚ Complication (Widget)
- **At-a-Glance Status**: See exactly how much time is left until the next check-in directly on the watch face.
- **Custom Formatting**: Displays clear "2h 30m" or "15m" text updates (no seconds) for readability.
- **Instant Sync**: Uses App Groups to synchronize timer state between the App and Widget instantly.

### 📊 History & HealthKit
- **7-Day History**: View a color-coded log of the last week's events directly on the watch.
- **HealthKit Integration**: securely saves data to Apple Health.
    - Uses `HKCategoryTypeIdentifier.intermittentVoiding` (or fallback) for Pee.
    - Uses `HKCategoryTypeIdentifier.bowelMovement` for Poop with Bristol Scale metadata.
    - **Simulator Support**: Includes fallback logic to save data even on simulators that miss specific HealthKit types.

## Technical Details

- **Platform**: watchOS 10+
- **Technologies**: SwiftUI, HealthKit, WidgetKit, Combine.
- **Data Persistence**: `UserDefaults` (shared via App Groups) for Timer state; HealthKit for Event logs.

## Setup Requirements

### App Groups
To ensure the Complication syncs correctly with the App, you must configure **App Groups** in Xcode:
1.  Select the Project -> **GoTime Watch App** Target -> Signing & Capabilities -> + Capability -> **App Groups**.
2.  Add/Select `group.com.justinsc.GoTime`.
3.  Repeat for the **GoTimerWidgetExtension** Target.

### HealthKit Permissions
The app requires permission to Read/Write:
- `Intermittent Voiding`
- `Bowel Movements`
- `Abdominal Cramps` (Fallback/Medication)

## Installation

1.  Clone the repository.
2.  Open `GoTime.xcodeproj` in Xcode.
3.  Ensure your Development Team is selected for signing.
4.  Run on Apple Watch (Series 4 or later recommended) or Simulator.
