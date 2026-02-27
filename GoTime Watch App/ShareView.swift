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
                    VStack(spacing: 12) {
                        Text("Ready to connect!")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        ShareLink(item: url.absoluteString, subject: Text("GoTime Link"), message: Text("Paste this link into the GoTime Parent Dashboard: \(url.absoluteString)")) {
                            Label("Send Link", systemImage: "paperplane.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
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
