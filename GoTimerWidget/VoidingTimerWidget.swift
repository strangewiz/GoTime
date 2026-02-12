import WidgetKit
import SwiftUI

@main
struct VoidingTimerWidget: Widget {
    let kind: String = "VoidingTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VoidingTimerEntryView(entry: entry)
        }
        .configurationDisplayName("Void Timer")
        .description("Time until next check-in.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), displayString: "2h 30m", isOverdue: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let state = calculateState(target: getTargetDate(), at: Date())
        let entry = SimpleEntry(date: Date(), displayString: state.text, isOverdue: state.isOverdue)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let target = getTargetDate()
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        // Generate entries for the next hour (60 minutes)
        // The system will request a new timeline after the last entry
        for offset in 0..<60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: offset, to: currentDate)!
            let state = calculateState(target: target, at: entryDate)
            
            let entry = SimpleEntry(date: entryDate, displayString: state.text, isOverdue: state.isOverdue)
            entries.append(entry)
            
            // If we reached the target (overdue), we can stop adding specific countdowns 
            // and just stay on "Check In!" or add one final entry.
            if state.isOverdue {
                break
            }
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    // Helper to format text
    func calculateState(target: Date, at date: Date) -> (text: String, isOverdue: Bool) {
        let remaining = target.timeIntervalSince(date)
        
        if remaining <= 0 {
            return ("CHECK IN!", true)
        }
        
        let hours = Int(remaining) / 3600
        let minutes = Int(remaining) / 60 % 60
        
        if hours > 0 {
            return ("\(hours)h \(minutes)m", false)
        } else {
            return ("\(minutes)m", false)
        }
    }
    
    func getTargetDate() -> Date {
        let defaults = UserDefaults(suiteName: "group.com.justinsc.GoTime") // Must match App Group ID
        // Default to *now* + 2.5h (simulated) if missing, but ideally we show "Setup" or similar?
        // Let's stick to 2.5h default so it looks like a timer.
        return defaults?.object(forKey: "targetVoidTime") as? Date ?? Date().addingTimeInterval(3600 * 2.5)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let displayString: String
    let isOverdue: Bool
}

struct VoidingTimerEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        Text(entry.displayString)
            .multilineTextAlignment(.center)
            .font(.headline)
            .minimumScaleFactor(0.5) // Allow shrinking to fit
            .foregroundColor(entry.isOverdue ? .red : .primary)
            .containerBackground(for: .widget) {
                Color.black // watchOS 10 container background
            }
    }
}
