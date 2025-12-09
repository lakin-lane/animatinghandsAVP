/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model to maintain app-wide state.
*/

import SwiftUI
import ARKit

/// Maintains app-wide state.
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    var handTrackingAuthorizationStatus: ARKitSession.AuthorizationStatus = .notDetermined
    
    /// Requests hands-tracking authorization and continuously monitors for status changes.
    func observeHandTrackingAuthorizationStatus() async {
        // The sample uses this instance to monitor for authorization changes.
        let arkitSession = ARKitSession()
        let authorizationResults = await arkitSession.requestAuthorization(for: [.handTracking])
        
        if let status = authorizationResults[.handTracking] {
            handTrackingAuthorizationStatus = status
        }
        
        for await event in arkitSession.events {
            guard case .authorizationChanged(let type, let status) = event,
                  type == .handTracking else {
                continue
            }

            handTrackingAuthorizationStatus = status
        }
    }
}
