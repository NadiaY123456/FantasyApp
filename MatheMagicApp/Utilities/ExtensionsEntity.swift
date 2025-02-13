import ARKit
import Combine
import RealityKit
import SwiftUI

// for gestures
extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}

extension Entity {
    func forward(relativeTo referenceEntity: Entity?) -> SIMD3<Float> {
        normalize(convert(direction: SIMD3<Float>(0, 0, +1), to: referenceEntity))
    }
}


extension Entity {
    func setMaterialParameterValues(parameter: String, value: MaterialParameters.Value) {
        let modelEntities = descendentsWithModelComponent
        for entity in modelEntities {
            if var modelComponent = entity.modelComponent {
               
                modelComponent.materials = modelComponent.materials.map {
                    
                    guard var material = $0 as? ShaderGraphMaterial else { return $0 }
                    if material.parameterNames.contains(parameter) {
                        do {
                            try material.setParameter(name: parameter, value: value)
                        } catch {
                            AppLogger.shared.error("Error setting parameter: \(error.localizedDescription)")
                        }
                    }
                    return material
                }
                entity.modelComponent = modelComponent
            }
        }
    }
    
    subscript(parentMatching targetName: String) -> Entity? {
        if name.contains(targetName) {
            return self
        }
        
        guard let nextParent = parent else {
            return nil
        }
        
        return nextParent[parentMatching: targetName]
    }
    
    func getParent(nameBeginsWith name: String) -> Entity? {
        if self.name.hasPrefix(name) {
            return self
        }
        guard let nextParent = parent else {
            return nil
        }
        
        return nextParent.getParent(nameBeginsWith: name)
    }
    
    func getParent(withName name: String) -> Entity? {
        if self.name == name {
            return self
        }
        guard let nextParent = parent else {
            return nil
        }
        
        return nextParent.getParent(withName: name)
    }
    
    subscript(descendentMatching targetName: String) -> Entity? {
        if name.contains(targetName) {
            return self
        }
        
        var match: Entity? = nil
        for child in children {
            match = child[descendentMatching: targetName]
            if let match = match {
                return match
            }
        }
        
        return match
    }
    
    func getSelfOrDescendent(withName name: String) -> Entity? {
        if self.name == name {
            return self
        }
        var match: Entity? = nil
        for child in children {
            match = child.getSelfOrDescendent(withName: name)
            if match != nil {
                return match
            }
        }
        
        return match
    }
    
    var forward: SIMD3<Float> {
        forward(relativeTo: nil)
    }
}


extension Entity {
    func addSkybox(for destination: Destination) {
        let subscription = TextureResource.loadAsync(named: destination.imageName).sink(
            receiveCompletion: {
                switch $0 {
                case .finished: break
                case .failure(let error): assertionFailure("\(error)")
                }
            },
            receiveValue: { [weak self] texture in
                guard let self = self else { return }
                var material = UnlitMaterial()
                material.color = .init(texture: .init(texture))
                self.components.set(ModelComponent(
                    mesh: .generateSphere(radius: 1e3),
                    materials: [material]
                ))
                // We flip the sphere inside out so the texture is shown inside.
                self.scale *= .init(x: -1, y: 1, z: 1)
                self.transform.translation += SIMD3<Float>(0.0, 1.0, 0.0)

                // Rotate the sphere to show the best initial view of the space.
                updateRotation(for: destination)
            }
        )
        components.set(Entity.SubscriptionComponent(subscription: subscription))
    }

    func updateTexture(for destination: Destination) {
        let subscription = TextureResource.loadAsync(named: destination.imageName).sink(
            receiveCompletion: {
                switch $0 {
                case .finished: break
                case .failure(let error): assertionFailure("\(error)")
                }
            },
            receiveValue: { [weak self] texture in
                guard let self = self else { return }

                guard var modelComponent = self.components[ModelComponent.self] else {
                    fatalError("Should this be fatal? Probably.")
                }

                var material = UnlitMaterial()
                material.color = .init(texture: .init(texture))
                modelComponent.materials = [material]
                self.components.set(modelComponent)

                // Rotate the sphere to show the best initial view of the space.
                updateRotation(for: destination)
            }
        )
        components.set(Entity.SubscriptionComponent(subscription: subscription))
    }

    func updateRotation(for destination: Destination) {
        // Rotate the immersive space around the Y-axis set the user's
        // initial view of the immersive scene.
        let angle = Angle.degrees(destination.rotationDegrees)
        let rotation = simd_quatf(angle: Float(angle.radians), axis: SIMD3<Float>(0, 1, 0))
        transform.rotation = rotation
    }

    /// A container for the subscription that comes from asynchronous texture loads.
    ///
    /// In order for async loading callbacks to work we need to store
    /// a subscription somewhere. Storing it on a component will keep
    /// the subscription alive for as long as the component is attached.
    struct SubscriptionComponent: Component {
        var subscription: AnyCancellable
    }
}

// for skyboxes
enum Destination: String, CaseIterable, Identifiable, Codable {
    case ruralRoad
    case fairy_forest_day
    case forest

    var id: Self { self }

    /// The environment image to load.
    var imageName: String { "Meadow_sky_bake_v2" }

    /// A number of degrees to rotate the 360 "destination" image to provide the best initial view.
    var rotationDegrees: Double {
        switch self {
        case .ruralRoad: 55
        case .fairy_forest_day: -55
        case .forest: 0
        }
    }
}

//// for Gestures
//
////  HandTracking.swift
////  HandMeasure
////
////  Created by Basuke Suzuki on 2/14/24.
//
//extension HandAnchor {
////    // return index finger tip joint if available
////    func indexFingerTipJoint() -> HandSkeleton.Joint? {
////        guard isTracked,
////              let indexFingerTipJoint = handSkeleton?.joint(.indexFingerTip),
////              indexFingerTipJoint.isTracked else { return nil }
////        return indexFingerTipJoint
////    }
////
////    // nata: return joint if available
////    func availableJoint(of joint: HandSkeleton.Joint) -> HandSkeleton.Joint? {
////        guard isTracked,
////              let availableJoint = handSkeleton?.joint(.indexFingerTip),
////              availableJoint.isTracked else { return nil }
////        return availableJoint
////    }
//
//    // calculate the world position of a given joint
//    func worldPosition(of joint: HandSkeleton.Joint) -> simd_float3 {
//        matrix_multiply(
//            originFromAnchorTransform, joint.anchorFromJointTransform
//        ).columns.3.xyz
//    }
//}
//
//// to iterate over Chilarity:
//extension HandAnchor.Chirality: CaseIterable {
//    public static var allCases: [HandAnchor.Chirality] = [.left, .right]
//}
//
//public extension HandSkeleton {
//    // to iterate over finger names
//    enum FingerName: String, CaseIterable, Identifiable {
//        public var id: String { rawValue }
//
//        case thumb, indexFinger, middleFinger, ringFinger, littleFinger
//    }
//
//    // returns an array of joint objects for specified finger
//    struct Finger {
//        public let name: FingerName
//        public let joints: [Joint]
//
//        // methods to check if any of the joints for a particular finger is tracked and if it's a thumb.
//        public var isTracked: Bool {
//            joints.contains { $0.isTracked }
//        }
//
//        public var isTrackedCompletely: Bool {
//            joints.allSatisfy { $0.isTracked }
//        }
//
//        public var isThumb: Bool {
//            name == .thumb
//        }
//
//        // Defines a Finger struct that represents a finger with a name and an array of joints
//        private static func jointNames(_ name: FingerName) -> [JointName] {
//            switch name {
//            case .thumb:
//                [.thumbTip, .thumbIntermediateTip, .thumbIntermediateBase, .thumbKnuckle]
//            case .indexFinger:
//                [.indexFingerTip, .indexFingerIntermediateTip, .indexFingerIntermediateBase, .indexFingerKnuckle]
//            case .middleFinger:
//                [.middleFingerTip, .middleFingerIntermediateTip, .middleFingerIntermediateBase, .middleFingerKnuckle]
//            case .ringFinger:
//                [.ringFingerTip, .ringFingerIntermediateTip, .ringFingerIntermediateBase, .ringFingerKnuckle]
//            case .littleFinger:
//                [.littleFingerTip, .littleFingerIntermediateTip, .littleFingerIntermediateBase, .littleFingerKnuckle]
//            }
//        }
//
//        // Provides a method to get a specific finger from the hand skeleton.
//        init(name: FingerName, from skeleton: HandSkeleton) {
//            let joints = Self.jointNames(name).map { skeleton.joint($0) }
//            assert(joints.count >= 3)
//
//            self.name = name
//            self.joints = joints
//        }
//    }
//
//    // Returns info about all joints for a given finger.
//    func finger(_ name: FingerName) -> Finger {
//        Finger(name: name, from: self)
//    }
//
//    // provide left and right fingers
//    var fingers: [Finger] {
//        FingerName.allCases.map { finger($0) }
//    }
//
//    internal var rootJoint: Joint {
//        allJoints.first(where: { $0.parentJoint == nil })!
//    }
//
//    internal var leafJoints: [Joint] {
//        let leafJointNames: Set<JointName> = Set([.thumbTip, .indexFingerTip, .middleFingerTip, .ringFingerTip, .littleFingerTip, .forearmArm])
//        return allJoints.filter { leafJointNames.contains($0.name) }
//    }
//}
//
//extension HandSkeleton.Joint: Identifiable {
//    public var id: HandSkeleton.JointName {
//        name
//    }
//}
//
//public extension HandSkeleton.Joint {
//    // get angle of the joint
//    var angle: Float {
//        let quat = simd_quatf(parentFromJointTransform)
//        return quat.angle
//    }
//
//    var rotation: (roll: Float, pitch: Float, yaw: Float) {
//        let rotation = extractEulerAngles(from: parentFromJointTransform)
//        return rotation
//    }
//
//    // get position of the joint relative to wrist
//    var relativePosition: simd_float3 {
//        anchorFromJointTransform.columns.3.xyz
//    }
//
//    // calculate the distance to another joint
//    func distance(to other: Self) -> Float {
//        let vec = relativePosition - other.relativePosition
//        return vec.length
//    }
//
//    // Function to extract Euler angles from simd_float4x4 matrix
//    private func extractEulerAngles(from matrix: simd_float4x4) -> (roll: Float, pitch: Float, yaw: Float) {
//        let sy = sqrt(matrix.columns.0.x * matrix.columns.0.x + matrix.columns.1.x * matrix.columns.1.x)
//        let singular = sy < 1e-6 // If
//
//        var x, y, z: Float
//        if !singular {
//            x = atan2(matrix.columns.2.y, matrix.columns.2.z)
//            y = atan2(-matrix.columns.2.x, sy)
//            z = atan2(matrix.columns.1.x, matrix.columns.0.x)
//        } else {
//            x = atan2(-matrix.columns.1.z, matrix.columns.1.y)
//            y = atan2(-matrix.columns.2.x, sy)
//            z = 0
//        }
//
//        // Convert radians to degrees
//        let roll = -1 * x * 180 / .pi
//        let pitch = -1 * y * 180 / .pi
//        let yaw = -1 * z * 180 / .pi
//
//        return (roll, pitch, yaw)
//    }
//}
//
//public extension HandAnchor {
//    typealias FingerName = HandSkeleton.FingerName
//
//    // Defines a Joint struct that represents a joint with a position, angle, and tracking status.
//    struct Joint: Identifiable {
//        public var id: HandSkeleton.JointName { name }
//
//        public let name: HandSkeleton.JointName
//        public let position: simd_float3
//        public let angle: Float
//        public let roll: Float
//        public let pitch: Float
//        public let yaw: Float
//        public let isTracked: Bool
//
//        init(handAnchor: HandAnchor, joint: HandSkeleton.Joint) {
//            name = joint.name
//            position = handAnchor.worldPosition(of: joint)
//            angle = joint.angle
//            roll = joint.rotation.roll
//            pitch = joint.rotation.pitch
//            yaw = joint.rotation.yaw
//            isTracked = joint.isTracked
//        }
//    }
//
//    // Defines a Finger struct that represents a finger with a tip, an array of joints, and a knuckle, and includes methods to calculate the bend and angle of the finger.
//    struct Finger {
//        public let name: FingerName
////        public let tip: Joint
//        public let joints: [Joint]
////        public let knuckle: Joint
//
//        public var bend: Float {
//            guard !joints.isEmpty else { return .zero } // Nata: should it be Nil? orig: .zero
//            return joints.reduce(0.0) { $0 + $1.angle } / Float(joints.count)
//        }
//
//        init(handAnchor: HandAnchor, finger: HandSkeleton.Finger) {
//            name = finger.name
//            let joints = finger.joints.map { joint in
//                Joint(handAnchor: handAnchor, joint: joint)
//            }
//
////            tip = joints.removeFirst()
////            knuckle = joints.removeLast()
//            self.joints = joints
//        }
//    }
//
//    internal struct Palm {}
//
//    // Defines a Hand struct that represents a hand with chirality, fingers, a transform relative to the wrist, and a tracking status, and includes a method to parse a HandAnchor into a Hand.
//
//    struct Hand {
//        public let chirality: HandAnchor.Chirality
//        public let fingers: [FingerName: Finger]
//        public let originFromAnchorTransform: simd_float4x4
//        public let isTracked: Bool
//
//        init?(handAnchor: HandAnchor) {
//            guard let skeleton = handAnchor.handSkeleton else {
//                return nil
//            }
//
//            var fingers: [FingerName: Finger] = [:]
//
//            for finger in skeleton.fingers {
//                fingers[finger.name] = Finger(handAnchor: handAnchor, finger: finger)
//            }
//
//            chirality = handAnchor.chirality
//            self.fingers = fingers
//            originFromAnchorTransform = handAnchor.originFromAnchorTransform
//            isTracked = handAnchor.isTracked
//        }
//    }
//
//    func parse() -> Hand? {
//        Hand(handAnchor: self)
//    }
//}
//
//// class with a configuration and methods to recognize hand shapes and determine the state of a finger based on its angle and bend.
//class HandShapeRecogniser {
//    typealias FingerName = HandSkeleton.FingerName
//    typealias Hand = HandAnchor.Hand
//    typealias Finger = HandAnchor.Finger
//    typealias Joint = HandAnchor.Joint
//
//    // struct to hold configuration parameters for recognizing hand shapes
//    struct Configuration {
//        let bendMinMax: [FingerName: (Float, Float)]
//        let defaultBendMinMax: (Float, Float)
//
//        func bendMinMax(of finger: FingerName) -> (Float, Float) {
//            if let result = bendMinMax[finger] {
//                result
//            } else {
//                defaultBendMinMax
//            }
//        }
//
//        static var standard: Self {
//            Self(
//                bendMinMax: [:],
//                defaultBendMinMax: (0.3, 2.0)
//            )
//        }
//    }
//
//    let config: Configuration
//
//    init(config: Configuration = .standard) {
//        self.config = config
//    }
//
//    enum FingerState: String, Equatable {
//        case relaxed, curled, straight, unknown
//    }
//
//    struct Result {}
//
//    func recognize(hand: Hand) -> Result {
//        return Result()
//    }
//
//    func state(of finger: Finger, angle: Float, bend: Float) -> FingerState {
//        let (min, max) = config.bendMinMax(of: finger.name)
//
//        return if bend < min {
//            .straight
//        } else if bend > max {
//            .curled
//        } else {
//            .relaxed
//        }
//    }
//}
//
//class HandPoseRecogniser {
//    typealias FingerName = HandSkeleton.FingerName
//    typealias Hand = HandAnchor.Hand
//    typealias Finger = HandAnchor.Finger
//    typealias Joint = HandAnchor.Joint
//
//    // struct to hold configuration parameters for recognizing hand shapes
//    struct Configuration {
//        let bendMinMax: [FingerName: (Float, Float)]
//        let defaultBendMinMax: (Float, Float)
//
//        func bendMinMax(of finger: FingerName) -> (Float, Float) {
//            if let result = bendMinMax[finger] {
//                result
//            } else {
//                defaultBendMinMax
//            }
//        }
//
//        static var standard: Self {
//            Self(
//                bendMinMax: [:],
//                defaultBendMinMax: (10, 80) // angle in degrees
//            )
//        }
//    }
//
//    let config: Configuration
//
//    init(config: Configuration = .standard) {
//        self.config = config
//    }
//
//    enum FingerPose: String, Equatable {
//        case flexion, curled, bent, unknown, fullyStraight
//    }
//
//    struct Result {}
//
//    func recognize(hand: Hand) -> Result {
//        return Result()
//    }
//
//    func fingerPose(of finger: Finger) -> FingerPose {
//
//        if finger.name == .middleFinger {
////            print("middle int tip yaw  \(finger.joints[1].yaw)")
////            print("middle base yaw     \(finger.joints[2].yaw)")
////            print("middle knuckle yaw  \(finger.joints[3].yaw)")
//        }
//
//        if finger.name != .thumb {
//            if finger.joints[2].isTracked && finger.joints[2].yaw < 15 { // base
//                if finger.joints[1].isTracked && finger.joints[1].yaw < 15 { // intermedite tip
//                    if finger.joints[3].isTracked && finger.joints[3].yaw < 10 { // knuckle
//                        return .fullyStraight
//                    } else if finger.joints[3].isTracked {
//                        return .flexion
//                    } else { return .unknown }
//                } else {
//                    return .unknown
//                }
//            } else if finger.joints[2].isTracked && finger.joints[2].yaw > 80 { // base
//                if finger.joints[3].isTracked && finger.joints[3].yaw > 50 { // knuckle
//                    return .curled
//                } else if finger.joints[3].isTracked {
//                    return .bent
//                } else {return .unknown}
//            } else { return .unknown }
//        } else { // if Thumb
//            if finger.joints[1].isTracked && finger.joints[1].yaw < 5 { // intermedite tip which is like base for thumb
//                if finger.joints[2].isTracked && finger.joints[2].yaw < 10 { // base which is like knuckle for thumb
//                    return .fullyStraight
//                } else if finger.joints[2].isTracked {
//                    return .flexion
//                } else { return .unknown }
//            } else if finger.joints[1].isTracked && finger.joints[1].yaw > 40 { // intermedite tip which is like base for thumb
//                if finger.joints[2].isTracked && finger.joints[2].yaw > 25 { // base which is like knuckle for thumb
//                    return .curled
//                } else {
//                    return .unknown
//                } 
//            } else { return .unknown }
//        }
//    }
//}
//
//// Adds a computed property length to simd_float3 to get the length of the vector and a method distance(to:) to calculate the distance between two vectors.
////public extension simd_float3 {
////    var length: Float {
////        sqrt(x * x + y * y + z * z)
////    }
////
////    func distance(to other: Self) -> Float {
////        (other - self).length
////    }
////}
//
////            let rightLittleFinger = rightHandAnchor.parse()?.fingers[.littleFinger]
////        let dist = thumbTipJoint.distance(to: indexFingerIntermediateTipJoint)
////
//// enum HandPose {
////    static func from(straightFingersCount: Int, curledFingersCount: Int) -> Self {
////        if straightFingersCount >= 4 {
////            return .openPalm
////        } else if curledFingersCount == 5 {
////            return .fist
////        } else {
////            return .undefined
////        }
////    }
////
////    case openPalm
////    case fist
////    case undefined
////    case notTracked
//// }
//
//
//
//
