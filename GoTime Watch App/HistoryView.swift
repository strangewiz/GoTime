import SwiftUI

struct HistoryView: View {
    @State private var logs: [LogEntry] = []
    @State private var isLoading = true
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
            } else if logs.isEmpty {
                Text("No logs in past 7 days.")
                    .foregroundColor(.gray)
            } else {
                ForEach(logs) { log in
                    HStack {
                        Circle()
                            .fill(color(for: log.type))
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading) {
                            Text(title(for: log))
                                .font(.headline)
                            Text(formatDate(log.date))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if let meta = log.metadata {
                            Text(meta)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("History")
        .onAppear {
            fetchLogs()
        }
    }
    
    func fetchLogs() {
        HealthKitManager.shared.fetchHistory { fetchedLogs in
            self.logs = fetchedLogs
            self.isLoading = false
        }
    }
    
    func color(for type: LogEntry.LogType) -> Color {
        switch type {
        case .pee: return .blue
        case .poop: return .brown
        case .miralax: return .green
        }
    }
    
    func title(for log: LogEntry) -> String {
        switch log.type {
        case .pee: return "Pee"
        case .poop: return "Poop"
        case .miralax: return "Miralax"
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E M/d h:mm a"
        return formatter.string(from: date)
    }
}
