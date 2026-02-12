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
                    
                    // Pee Button
                    Button(action: {
                        showingPeeConfirmation = true
                    }) {
                        Text("Log PEE")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .alert(isPresented: $showingPeeConfirmation) {
                        Alert(
                            title: Text("Log Pee?"),
                            message: Text("Confirm logging at \(currentTimeString())"),
                            primaryButton: .default(Text("Confirm")) {
                                logPee()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    
                    // Poop Button
                    Button(action: {
                        showingBristol = true
                    }) {
                        Text("Log POOP")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.brown)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showingBristol) {
                        BristolScaleView()
                    }
                    
                    Divider()
                    
                    // Miralax
                    Toggle(isOn: $miralaxTaken) {
                        Text("Morning Meds")
                            .font(.headline)
                    }
                    .onChange(of: miralaxTaken) { newValue in
                        if newValue {
                            HealthKitManager.shared.logMiralax()
                            WKInterfaceDevice.current().play(.success)
                        }
                    }
                    .padding(.horizontal)
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
    
    func logPee() {
        HealthKitManager.shared.logPee()
        timerManager.resetTimer()
        WKInterfaceDevice.current().play(.success)
    }
    
    func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}
