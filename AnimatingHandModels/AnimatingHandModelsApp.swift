/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An app that substitutes the Apple Vision Pro wearer's hands with animated glove models in a fully immersive space.
*/

import SwiftUI

@main
struct AnimatingHandModelsApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .task {
                    await appModel.observeHandTrackingAuthorizationStatus()
                }
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
        .upperLimbVisibility(.hidden)
    }
}
