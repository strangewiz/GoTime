import SwiftUI

struct HistoryView: View {
    @State private var logs: [LogEntry] = []
    
    var body: some View {
        List {
            if logs.isEmpty {
                Text("No history yet.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(logs) { log in
                    HStack {
                        icon(for: log.type, metadata: log.extraData)
                        
                        VStack(alignment: .leading) {
                            Text(title(for: log.type))
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(timeString(from: log.date))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            if let meta = log.extraData {
                                Text(meta)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("History")
        .onAppear {
            loadHistory()
        }
    }
    
    func loadHistory() {
        logs = HistoryManager.shared.getRecentLogs()
    }
    
    func icon(for type: LogEntry.LogType, metadata: String?) -> some View {
        // ... (Icon logic - we can reuse or just use system images for now to simplify?)
        // Let's copy the icon logic but simplified
        switch type {
        case .pee:
            return Circle().fill(Color.blue).frame(width: 10, height: 10)
        case .poop:
            return Circle().fill(Color.brown).frame(width: 12, height: 12)
        case .miralax:
            return Circle().fill(Color.purple).frame(width: 8, height: 8)
        }
    }
    
    func title(for type: LogEntry.LogType) -> String {
        switch type {
        case .pee: return "Pee"
        case .poop: return "Poop"
        case .miralax: return "Miralax"
        }
    }
    
    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE h:mm a"
        return formatter.string(from: date)
    }
}
