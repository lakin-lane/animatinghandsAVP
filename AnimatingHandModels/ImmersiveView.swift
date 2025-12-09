/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays animated glove models that track the Apple Vision Pro wearer's hands.
*/

import SwiftUI
import RealityKit
import ARKit

struct ImmersiveView: View {
    @State private var arkitSession = ARKitSession()
    @State private var handTrackingProvider = HandTrackingProvider()
    @State private var leftGlove: ModelEntity?
    @State private var rightGlove: ModelEntity?
    
    var body: some View {
        RealityView { content in
            let root = Entity()
            
            if let glove = await loadGloveModel(named: "LeftGlove") {
                leftGlove = glove
                root.addChild(glove)
            }
            
            if let glove = await loadGloveModel(named: "RightGlove") {
                rightGlove = glove
                root.addChild(glove)
            }
            
            content.add(root)
        }
        .task {
            await startHandTracking()
        }
    }
    
    private func loadGloveModel(named name: String) async -> ModelEntity? {
        if let url = Bundle.main.url(forResource: name, withExtension: "usdz") {
            do {
                let glove = try await ModelEntity(contentsOf: url)
                let gloveJointCount = glove.jointNames.count
                let expectedJointCount = HandSkeleton.JointName.allCases.count

                guard gloveJointCount == expectedJointCount else {
                    print("""
                        Joint count mismatch: USD model (\(name)) has \(gloveJointCount) joints, \
                        but ARKit hand skeleton has \(expectedJointCount) joints.
                        """)
                    return nil
                }
                
                return glove
            } catch {
                print("Failed to load \(name): \(error.localizedDescription).")
            }
        } else {
            print("Glove model not found in bundle: \(name).")
        }
        
        return nil
    }

    private func startHandTracking() async {
        do {
            try await arkitSession.run([handTrackingProvider])
        } catch {
            print("Failed to start hand tracking: \(error.localizedDescription).")
        }
        
        await updateGlovesFromHandAnchors()
    }
    
    private func updateGlovesFromHandAnchors() async {
        for await anchorUpdate in handTrackingProvider.anchorUpdates {
            let handAnchor = anchorUpdate.anchor
            
            guard let glove = handAnchor.chirality == .left ? leftGlove : rightGlove,
                  let handSkeleton = handAnchor.handSkeleton else { continue }
            
            // Hide the glove when the system loses tracking.
            glove.isEnabled = handAnchor.isTracked
            
            guard handAnchor.isTracked else { continue }
            
            glove.transform = Transform(matrix: handAnchor.originFromAnchorTransform)
            updateJointRotations(for: glove, using: handSkeleton)
        }
    }
    
    private func updateJointRotations(for glove: ModelEntity, using handSkeleton: HandSkeleton) {
        let joints = handSkeleton.allJoints
        
        // This assumes the joint order in the USD file matches the ARKit hand skeleton joint order.
        for (index, joint) in joints.enumerated() {
            let jointTransform = handSkeleton.joint(joint.name).parentFromJointTransform
            let rotation = simd_quatf(jointTransform)
            
            glove.jointTransforms[index].rotation = rotation
        }
    }
}
