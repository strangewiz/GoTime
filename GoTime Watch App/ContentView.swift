import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject var timerManager = TimerManager()
    @State private var showingBristol = false
    @State private var showingPeeConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    // Timer display
                    VStack {
                        Text(timerManager.timeString)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(timerManager.isOverdue ? .red : .white)
                        
                        if timerManager.isOverdue || timerManager.progress < 0.2 {
                            Button(action: {
                                timerManager.snooze()
                            }) {
                                Text("Snooze 10m")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 5)
                    
                    // MARK: - Actions
                    HStack(spacing: 12) {
                        // Log Pee Button
                        Button(action: {
                            showingPeeConfirmation = true
                        }) {
                            VStack {
                                Image(systemName: "drop.fill")
                                    .font(.title2)
                                Text("Log PEE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .alert(isPresented: $showingPeeConfirmation) {
                            Alert(
                                title: Text("Log Pee?"),
                                message: Text("Confirm logging at \(currentTimeString())"),
                                primaryButton: .default(Text("Confirm")) {
                                    // Log Pee Action
                                    timerManager.resetTimer()
                                    HistoryManager.shared.addEntry(type: .pee) 
                                    WKInterfaceDevice.current().play(.success)
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        
                        // Log Poop Button
                        Button(action: {
                            showingBristol = true
                        }) {
                            VStack {
                                Image(systemName: "circle.grid.hex.fill")
                                    .font(.title2)
                                Text("Log POOP")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.brown.opacity(0.8))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .sheet(isPresented: $showingBristol) {
                            BristolScaleView()
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Settings Link
                    NavigationLink(destination: SettingsView(timerManager: timerManager)) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                // HealthKitManager.shared.requestAuthorization()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: HistoryView()) {
                        Image(systemName: "list.bullet.clipboard")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: ShareView()) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var showingClearAlert = false
    @State private var showingClearSuccess = false
    
    // Interval options (in minutes)
    let intervalOptions: [Double] = [30, 60, 90, 120, 150, 180, 210, 240]
    
    // Format minutes into hours & mins
    func formatLabel(mins: Double) -> String {
        let h = Int(mins) / 60
        let m = Int(mins) % 60
        if h > 0 && m > 0 {
            return "\(h)h \(m)m"
        } else if h > 0 {
            return "\(h) hours"
        }
        return "\(m) mins"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                
                Text("Timer Duration")
                    .font(.headline)
                    .padding(.top)
                
                // WatchOS Picker
                Picker("Duration", selection: Binding(
                    get: { timerManager.interval / 60.0 },
                    set: { timerManager.setInterval(minutes: $0) }
                )) {
                    ForEach(intervalOptions, id: \.self) { mins in
                        Text(formatLabel(mins: mins)).tag(mins)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 100)
                
                Divider().padding(.vertical, 8)

                Text("Sleep Window")
                    .font(.headline)
                
                Toggle("Pause at night", isOn: Binding(
                    get: { timerManager.isSleepEnabled },
                    set: { timerManager.setSleepSettings(enabled: $0, start: timerManager.sleepStartHour, end: timerManager.sleepEndHour) }
                ))
                
                if timerManager.isSleepEnabled {
                    HStack {
                        VStack {
                            Text("Start")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Picker("Start", selection: Binding(
                                get: { timerManager.sleepStartHour },
                                set: { timerManager.setSleepSettings(enabled: true, start: $0, end: timerManager.sleepEndHour) }
                            )) {
                                ForEach(0..<24, id: \.self) { h in
                                    Text("\(h):00").tag(h)
                                }
                            }
                            .frame(height: 60)
                            .labelsHidden()
                        }
                        
                        VStack {
                            Text("End")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Picker("End", selection: Binding(
                                get: { timerManager.sleepEndHour },
                                set: { timerManager.setSleepSettings(enabled: true, start: timerManager.sleepStartHour, end: $0) }
                            )) {
                                ForEach(0..<24, id: \.self) { h in
                                    Text("\(h):00").tag(h)
                                }
                            }
                            .frame(height: 60)
                            .labelsHidden()
                        }
                    }
                }
                
                Divider().padding(.vertical, 8)
                
                Text("Privacy")
                    .font(.headline)
                
                Button(role: .destructive, action: {
                    showingClearAlert = true
                }) {
                    Text("Clear All Data")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                }
                .alert(isPresented: $showingClearAlert) {
                    Alert(
                        title: Text("Clear Data?"),
                        message: Text("This will permanently delete your logs from this watch and CloudKit."),
                        primaryButton: .destructive(Text("Clear")) {
                            HistoryManager.shared.clearAllData()
                            showingClearSuccess = true
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .padding(.horizontal)
            .alert("Success", isPresented: $showingClearSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your local and remote history has been cleared.")
            }
        }
        .navigationTitle("Settings")
    }
}
