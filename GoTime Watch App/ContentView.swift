import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject var timerManager = TimerManager()
    @State private var showingBristol = false
    @State private var miralaxTaken = false
    @State private var showingPeeConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    // Timer Section
                    // ...

                    // ... (Timer display remains same)
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
                    .frame(maxWidth: .infinity)
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
                            HistoryManager.shared.addEntry(type: .pee) // New Logic
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
                    .frame(maxWidth: .infinity)
                    .background(Color.brown.opacity(0.8))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showingBristol) {
                    BristolScaleView()
                }
            }
            .padding(.horizontal)
            
            // MARK: - Miralax Toggle
            Toggle(isOn: $miralaxTaken) {
                Text("Morning Meds")
                    .font(.footnote)
            }
            .padding()
            .onChange(of: miralaxTaken) { newValue in
                if newValue {
                    HistoryManager.shared.addEntry(type: .miralax, extraData: "Daily Dose") // New logic
                    WKInterfaceDevice.current().play(.success)
                }
            }
                }
            }
            .onAppear {
                HealthKitManager.shared.requestAuthorization()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: HistoryView()) {
                        Image(systemName: "list.bullet.clipboard")
                            .foregroundColor(.white)
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
