import SwiftUI
import WatchKit

struct BristolScaleView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedScore: Int?
    @State private var showConfirmation = false
    
    let options = [
        (1, "Type 1: Hard Lumps", Color.brown.opacity(0.8)),
        (2, "Type 2: Lumpy Sausage", Color.brown.opacity(0.85)),
        (3, "Type 3: Cracked Sausage", Color.brown.opacity(0.9)),
        (4, "Type 4: Smooth Sausage", Color.brown),
        (5, "Type 5: Soft Blobs", Color.orange.opacity(0.8)),
        (6, "Type 6: Mushy", Color.orange.opacity(0.9)),
        (7, "Type 7: Liquid", Color.yellow)
    ]
    
    var body: some View {
        List {
            ForEach(options, id: \.0) { item in
                Button(action: {
                    selectedScore = item.0
                    showConfirmation = true
                }) {
                    HStack {
                        BristolGraphic(type: item.0, color: item.2)
                            .frame(width: 30, height: 20)
                            .padding(.trailing, 4)
                        
                        Text(item.1)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Stool Type")
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text("Log Poop?"),
                message: Text("Confirm Type \(selectedScore ?? 0) at \(currentTimeString())"),
                primaryButton: .default(Text("Confirm")) {
                    if let score = selectedScore {
                        logPoop(score: score)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    func logPoop(score: Int) {
        HealthKitManager.shared.logPoop(bristolScore: score)
        WKInterfaceDevice.current().play(.success)
        presentationMode.wrappedValue.dismiss()
    }
    
    func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

struct BristolGraphic: View {
    let type: Int
    let color: Color
    
    var body: some View {
        GeometryReader { _ in
            switch type {
            case 1: // Hard lumps
                HStack(spacing: 2) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Circle().fill(color).frame(width: 10, height: 10)
                    Circle().fill(color).frame(width: 7, height: 7)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case 2: // Lumpy Sausage
                ZStack {
                    Capsule().fill(color)
                    HStack(spacing: 3) {
                         Circle().fill(Color.black.opacity(0.1)).frame(width: 6, height: 6)
                         Circle().fill(Color.black.opacity(0.1)).frame(width: 7, height: 7)
                         Circle().fill(Color.black.opacity(0.1)).frame(width: 6, height: 6)
                    }
                }
            case 3: // Cracked Sausage
                ZStack {
                    Capsule().fill(color)
                    Path { path in
                        path.move(to: CGPoint(x: 10, y: 5))
                        path.addLine(to: CGPoint(x: 15, y: 15))
                        path.addLine(to: CGPoint(x: 20, y: 5))
                    }
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                }
            case 4: // Smooth Sausage
                Capsule().fill(color)
            case 5: // Soft Blobs
                HStack(spacing: 1) {
                    Capsule().fill(color).frame(width: 8, height: 12)
                    Capsule().fill(color).frame(width: 10, height: 14)
                    Capsule().fill(color).frame(width: 8, height: 12)
                }
            case 6: // Mushy
                ZStack {
                    Circle().fill(color).offset(x: -5, y: 2)
                    Circle().fill(color).offset(x: 5, y: -2)
                    Circle().fill(color).offset(x: 0, y: 0)
                }
                .scaleEffect(0.6)
            case 7: // Liquid
                Image(systemName: "drop.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(color)
            default:
                Circle().fill(color)
            }
        }
    }
}
