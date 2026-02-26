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
            if Task.isCancelled {
                return
            }

            let handAnchor = anchorUpdate.anchor

            guard
                let glove = (handAnchor.chirality == .left) ? leftGlove : rightGlove,
                let handSkeleton = handAnchor.handSkeleton
            else {
                continue
            }

            glove.isEnabled = handAnchor.isTracked

            guard handAnchor.isTracked else {
                continue
            }

            glove.transform = Transform(matrix: handAnchor.originFromAnchorTransform)
            
            updateJointRotations(for: glove, using: handSkeleton, chirality: handAnchor.chirality)
        }
    }
    
    private func updateJointRotations(for glove: ModelEntity, using handSkeleton: HandSkeleton, chirality: HandAnchor.Chirality) {
        let indexMap = gloveJointIndexMap(for: glove, chirality: chirality)

        for joint in handSkeleton.allJoints {

            guard let gloveIndex = indexMap[joint.name] else { continue }

            let jointTransform = handSkeleton.joint(joint.name).parentFromJointTransform
            let incomingRotation = simd_quatf(jointTransform)
            glove.jointTransforms[gloveIndex].rotation = incomingRotation
        }
    }
    
    private func gloveJointIndexMap(for glove: ModelEntity, chirality: HandAnchor.Chirality) -> [HandSkeleton.JointName: Int] {
        let names = glove.jointNames
        
        func find(_ suffix: String) -> Int? {
            names.firstIndex(where: { $0.hasSuffix("/\(suffix)") || $0 == suffix })
        }

        let side = (chirality == .left) ? "left" : "right"

        var map: [HandSkeleton.JointName: Int] = [:]

        map[.wrist] = names.firstIndex(where: { $0.hasSuffix("\(side)_hand_joint") })

        map[.forearmWrist] = find("\(side)_hand_twist_2_joint")
        map[.forearmArm]   = find("\(side)_forearm_joint")

        map[.thumbKnuckle]          = find("\(side)_handThumbStart_joint")
        map[.thumbIntermediateBase] = find("\(side)_handThumb_1_joint")
        map[.thumbIntermediateTip]  = find("\(side)_handThumb_2_joint")
        map[.thumbTip]              = find("\(side)_handThumbEnd_joint")

        map[.indexFingerMetacarpal]       = find("\(side)_handIndexStart_joint")
        map[.indexFingerKnuckle]          = find("\(side)_handIndex_1_joint")
        map[.indexFingerIntermediateBase] = find("\(side)_handIndex_2_joint")
        map[.indexFingerIntermediateTip]  = find("\(side)_handIndex_3_joint")
        map[.indexFingerTip]              = find("\(side)_handIndexEnd_joint")

        map[.middleFingerMetacarpal]       = find("\(side)_handMidStart_joint")
        map[.middleFingerKnuckle]          = find("\(side)_handMid_1_joint")
        map[.middleFingerIntermediateBase] = find("\(side)_handMid_2_joint")
        map[.middleFingerIntermediateTip]  = find("\(side)_handMid_3_joint")
        map[.middleFingerTip]              = find("\(side)_handMidEnd_joint")

        map[.ringFingerMetacarpal]       = find("\(side)_handRingStart_joint")
        map[.ringFingerKnuckle]          = find("\(side)_handRing_1_joint")
        map[.ringFingerIntermediateBase] = find("\(side)_handRing_2_joint")
        map[.ringFingerIntermediateTip]  = find("\(side)_handRing_3_joint")
        map[.ringFingerTip]              = find("\(side)_handRingEnd_joint")

        map[.littleFingerMetacarpal]       = find("\(side)_handPinkyStart_joint")
        map[.littleFingerKnuckle]          = find("\(side)_handPinky_1_joint")
        map[.littleFingerIntermediateBase] = find("\(side)_handPinky_2_joint")
        map[.littleFingerIntermediateTip]  = find("\(side)_handPinky_3_joint")
        map[.littleFingerTip]              = find("\(side)_handPinkyEnd_joint")

        return map.compactMapValues { $0 }
    }
}
