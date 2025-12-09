/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays hands-tracking availability and authorization status, and provides a button to toggle the immersive space.
*/

import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        Group {
            if HandTrackingProvider.isSupported == false {
                ContentUnavailableView {
                    Text("Hand tracking isn't supported.")
                }
                description: {
                    Text("Run this app on a device that supports hand tracking.")
                }
            } else if appModel.handTrackingAuthorizationStatus == .denied {
                ContentUnavailableView {
                    Text("Hand tracking isn't allowed.")
                }
                description: {
                    Text("Allow hand tracking in Settings.")
                }
            } else if appModel.handTrackingAuthorizationStatus == .allowed {
                VStack {
                    ToggleImmersiveSpaceButton()
                }
            }
            
        }
        
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
