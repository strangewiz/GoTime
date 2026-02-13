import SwiftUI
import CloudKit

struct ShareView: View {
    @ObservedObject var cloudManager = CloudKitManager.shared
    
    var body: some View {
        VStack {
            Text("Parent Sharing")
                .font(.headline)
            
            if let share = cloudManager.share {
                // Share Link for watchOS 9+
                // Note: CKShare is not directly Transferable in standard Swift yet without wrappers in some contexts,
                // but usually Sharing a CKShare requires UICloudSharingController on iOS.
                // On watchOS, we can try ShareLink with the URL of the share?
                // share.url is the inviting URL.
                
                if let url = share.url {
                    ShareLink(item: url, subject: Text("Join GoTime History"), message: Text("Click to view my potty logs!")) {
                        Label("Invite Parent", systemImage: "person.badge.plus")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                } else {
                    Text("Preparing Share URL...")
                        .font(.caption)
                }
            } else {
                Button(action: {
                    cloudManager.fetchOrCreateShare()
                }) {
                    Text("Create Share Link")
                }
                .disabled(cloudManager.isSaving)
            }
            
            if let error = cloudManager.lastError {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            cloudManager.fetchOrCreateShare()
        }
    }
}
