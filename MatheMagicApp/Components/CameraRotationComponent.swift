//
//  CameraRotationComponent.swift
//  MatheMagic
//

import RealityKit
import SwiftUI

// MARK: - Camera Rotation Component

/// A component that stores drag & pinch state for camera updates.
/// Attach this component to the camera (or its pivot) so that the gesture system can update its rotation/zoom.
public struct CameraRotationComponent: Component {
    // MARK: Drag-related State

    public var dragStartAngle: Angle = .zero
    public var dragBaseline: CGFloat = 0.0
    public var lastDragTranslation: CGSize = .zero
    public var lastDragUpdateTime: TimeInterval = CACurrentMediaTime()
    public var lastDeltaX: CGFloat = 0.0

    // MARK: Pinch (Zoom) State

    public var initialPinchDistance: Float = 0.0
    public var lastPinchScale: CGFloat = 1.0

    public init() {}
}

// MARK: - Camera Rotation System

class CameraRotationSystem: System {
    @MainActor private static let query = EntityQuery(where: .has(CameraRotationComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    static var dependencies: [SystemDependency] { [] }

    func update(context: SceneUpdateContext) {
        let sharedView = GameModelView.shared
        let currentTime = CACurrentMediaTime()
        
        processDrag(in: context, sharedView: sharedView, currentTime: currentTime)
        processPinch(in: context, sharedView: sharedView)
    }
    
    // MARK: - Drag Processing
    
    /// Processes drag (rotation & pitch) updates.
    @MainActor
    private func processDrag(in context: SceneUpdateContext, sharedView: GameModelView, currentTime: TimeInterval) {
        let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        if sharedView.isDragging, let currentTranslation = sharedView.rawDragTranslation {
            for entity in entities {
                var gestureState = entity.components[CameraRotationComponent.self] ?? CameraRotationComponent()
                let dt = currentTime - gestureState.lastDragUpdateTime
                
                processHorizontalDrag(for: &gestureState, currentTranslation: currentTranslation, deltaTime: dt, sharedView: sharedView)
//                processVerticalDrag(for: &gestureState, currentTranslation: currentTranslation, sharedView: sharedView) //DO NOT DELETE THIS COMMENT!
                
                gestureState.lastDragTranslation = currentTranslation
                gestureState.lastDragUpdateTime = currentTime
                entity.components.set(gestureState)
                
                sharedView.camera.startSmoothCameraAnimation()
            }
        } else {
            // Lock in final values when not dragging.
            sharedView.camera.targetCameraYaw = sharedView.camera.cameraYaw
            sharedView.camera.targetCameraPitch = sharedView.camera.cameraPitch
            sharedView.camera.targetCameraDistance = sharedView.camera.cameraDistance
            
            for entity in entities {
                var gestureState = entity.components[CameraRotationComponent.self] ?? CameraRotationComponent()
                resetDragState(&gestureState, currentTime: currentTime)
                entity.components.set(gestureState)
            }
        }
    }
    
    /// Processes horizontal drag to update yaw.
    @MainActor
    private func processHorizontalDrag(for gestureState: inout CameraRotationComponent,
                                       currentTranslation: CGSize,
                                       deltaTime dt: TimeInterval,
                                       sharedView: GameModelView) {
        let deltaX = currentTranslation.width - gestureState.lastDragTranslation.width
        if abs(deltaX) < 1.0 || dt > 0.1 {
            sharedView.camera.targetCameraYaw = sharedView.camera.cameraYaw
            gestureState.dragStartAngle = sharedView.camera.cameraYaw
            gestureState.dragBaseline = currentTranslation.width
        } else {
            if gestureState.lastDeltaX * deltaX < 0 && abs(deltaX) > 1.0 {
                gestureState.dragStartAngle = sharedView.camera.cameraYaw
                gestureState.dragBaseline = currentTranslation.width
            }
            let effectiveDrag = currentTranslation.width - gestureState.dragBaseline
            sharedView.camera.targetCameraYaw = gestureState.dragStartAngle +
                Angle(radians: -Double(effectiveDrag) * sharedView.camera.settings.rotationSensitivity)
        }
        gestureState.lastDeltaX = deltaX
    }
    
    /// Processes vertical drag to update pitch and zoom.
    @MainActor
    private func processVerticalDrag(for gestureState: inout CameraRotationComponent,
                                     currentTranslation: CGSize,
                                     sharedView: GameModelView) {
        let deltaY = currentTranslation.height - gestureState.lastDragTranslation.height
        guard abs(deltaY) > 1.0 else { return }
        
        if deltaY > 0 {
            // Swiping downward: zoom in and tilt upward.
            let newDistance = sharedView.camera.targetCameraDistance - Float(deltaY) * 0.01
            sharedView.camera.targetCameraDistance = max(sharedView.camera.settings.minDistance, newDistance)
            
            let pitchUp = Double(deltaY) * 0.1
            let nextPitch = sharedView.camera.targetCameraPitch.degrees + pitchUp
            sharedView.camera.targetCameraPitch = .degrees(min(sharedView.camera.settings.maxPitch.degrees, nextPitch))
        } else {
            // Swiping upward: restore zoom (if needed) then tilt downward.
            if sharedView.camera.targetCameraDistance < sharedView.camera.lastPinchDistance {
                let newDistance = sharedView.camera.targetCameraDistance + Float(-deltaY) * 0.01
                sharedView.camera.targetCameraDistance = min(sharedView.camera.lastPinchDistance, newDistance)
            } else {
                let pitchDown = Double(deltaY) * 0.1
                let nextPitch = sharedView.camera.targetCameraPitch.degrees + pitchDown
                sharedView.camera.targetCameraPitch = .degrees(max(sharedView.camera.settings.minPitch.degrees, nextPitch))
            }
        }
    }
    
    /// Resets the drag state when no drag is occurring.
    @MainActor
    private func resetDragState(_ gestureState: inout CameraRotationComponent, currentTime: TimeInterval) {
        gestureState.lastDragTranslation = .zero
        gestureState.lastDeltaX = 0.0
        gestureState.dragBaseline = 0.0
        gestureState.lastDragUpdateTime = currentTime
    }
    
    // MARK: - Pinch Processing
    
    /// Processes pinch (zoom) updates.
    @MainActor
    private func processPinch(in context: SceneUpdateContext, sharedView: GameModelView) {
        let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        for entity in entities {
            var gestureState = entity.components[CameraRotationComponent.self] ?? CameraRotationComponent()
            if sharedView.isPinching {
                if gestureState.lastPinchScale == 1.0 {
                    gestureState.initialPinchDistance = sharedView.camera.cameraDistance
                }
                let scale = Float(sharedView.rawPinchScale)
                let newDistance = gestureState.initialPinchDistance * (1 - (scale - 1) * sharedView.camera.settings.zoomSensitivity)
                sharedView.camera.targetCameraDistance = min(sharedView.camera.settings.maxDistance,
                                                             max(sharedView.camera.settings.minDistance, newDistance))
                gestureState.lastPinchScale = sharedView.rawPinchScale
                sharedView.camera.startSmoothCameraAnimation()
            } else {
                gestureState.lastPinchScale = 1.0
                gestureState.initialPinchDistance = sharedView.camera.cameraDistance
            }
            entity.components.set(gestureState)
        }
    }
}


// MARK: - Camera State and Control

/// Nested struct in GameModelView for camera-specific state and functions.
/// Holds camera state, configuration parameters, and functions to update the camera transform.
class CameraState {
    // MARK: Adjustable Settings

    /// A nested struct grouping camera configuration parameters.
    struct Settings {
        /// Pitch boundaries (prevents 360° vertical spin)
        var minPitch: Angle = .degrees(-45) // e.g. 45° from above
        var maxPitch: Angle = .degrees(80)  // e.g. 80° from below
        
        /// Zoom boundaries
        var minDistance: Float = 2.0
        var maxDistance: Float = 12.0
        
        /// Offset for the pivot (e.g. center on a character’s knees rather than chest)
        var pivotOffset: SIMD3<Float> = SIMD3(0, -0.5, 0)
        
        // MARK: Parameters that affect horizontal rotation speed
        
        /// Smoothing and damping parameters
        var smoothingFactor: Float = 0.15 // Higher -> faster convergence
        var dampingFactor: Float = 0.01   // Higher -> more damping
        var maxRotationSpeed: Double =   4 * .pi // Maximum allowed rotation speed (radians per second)
        
        /// Sensitivity parameters for camera motions
        var rotationSensitivity: Double = 0.75 // Controls how fast the camera rotates based on drag
        var zoomSensitivity: Float = 2.0         // Controls how much zoom occurs per pinch
        
        /// Easing duration for interpolation (in seconds)
        var easingDuration: Double = 0.05

        // MARK: Additional Configurable Parameters

        /// Vertical offset for the camera’s local translation relative to the pivot.
        var cameraHeight: Float = 1.6

        /// Maximum allowed delta time per frame (in seconds) to clamp animation steps (approx. 60 fps).
        var maxDeltaTime: Double = 0.016

        /// Multiplier applied to the stabilization factor in smoothing calculations to reduce overshooting.
        var stabilizationFactorMultiplier: Double = 0.5

        /// Threshold below which differences are considered negligible, stopping the animation loop.
        var animationStopThreshold: Double = 0.001

        /// Sleep duration between animation frames in nanoseconds (approx. 60 fps).
        var animationFrameSleepNanoseconds: UInt64 = 16_000_000
    }
    
    // MARK: Camera State Properties
    /// The current values are what the camera is actually using at any given frame. The target values are where you eventually want the camera to end up.
    
    
    /// Should have the same default values to avoid a jump in the beginning
    var cameraDistance: Float = 4.0
    var targetCameraDistance: Float = 4.0
    var lastPinchDistance: Float = 4.0  /// Final pinch-based distance so we can "return" to it when swiping up.
    
    var cameraYaw: Angle = .zero
    var targetCameraYaw: Angle = .zero
    
    var cameraPitch: Angle = .degrees(-20)
    var targetCameraPitch: Angle = .degrees(-20)
    
    

    /// Adjustable parameters for the camera.
    var settings = Settings()

    // MARK: Scene Entities

    /// The pivot entity around which the camera rotates.
    var cameraPivot: Entity?
    /// The actual camera entity.
    var cameraEntity: Entity?
    /// The entity the camera orbits (e.g. a character).
    var trackedEntity: Entity?
    
    /// The skydome entity used for the skybox.
    var skydomeEntity: Entity?
    /// The base rotation for the skydome (derived from destination settings).
    var skydomeBaseRotation: simd_quatf = .init(angle: 0, axis: SIMD3(0, 1, 0))
    
    // MARK: Animation Control

    private var isAnimatingCamera = false
    private var lastUpdateTime: TimeInterval = CACurrentMediaTime()
    
    // MARK: - Camera Setup

    /// Adds a camera that orbits the tracked character.
    ///
    /// - Parameters:
    ///   - content: The RealityViewCameraContent to which the camera will be added.
    ///   - tracked: The entity that the camera will orbit.
    func addCamera(to content: RealityViewCameraContent, relativeTo tracked: Entity) {
        trackedEntity = tracked

        // Create a pivot entity at the tracked character’s position.
        let pivot = Entity()
        pivot.transform.translation = tracked.transform.translation + settings.pivotOffset

        // Attach the CameraRotationComponent so that the system can update it.
        pivot.components.set(CameraRotationComponent())
        content.add(pivot)
        cameraPivot = pivot

        // Create and configure the camera entity.
        let camera = Entity()
        camera.components.set(PerspectiveCameraComponent())
        // Use settings.cameraHeight for the vertical offset.
        camera.transform.translation = SIMD3(0, settings.cameraHeight, cameraDistance)
        pivot.addChild(camera)
        cameraEntity = camera

        // Immediately update the camera transform.
        updateCameraTransform()
    }
    
    // MARK: - Camera Transform Update

    /// Updates the camera and skydome transforms.
    ///
    /// - Note: This function:
    ///   - Updates the pivot’s position (following the tracked entity),
    ///   - Applies current yaw (cameraAngle) and pitch (cameraPitch),
    ///   - Sets the camera’s position (height and zoom), and
    ///   - Corrects the skydome rotation.
    func updateCameraTransform() {
        guard let pivot = cameraPivot, let camera = cameraEntity else { return }
        
        // Follow the tracked entity.
        if let tracked = trackedEntity {
            pivot.transform.translation = tracked.transform.translation + settings.pivotOffset
        }
        
        // Combine yaw and pitch rotations.
        let yawRotation = simd_quatf(angle: Float(cameraYaw.radians), axis: [0, 1, 0])
        let pitchRotation = simd_quatf(angle: Float(cameraPitch.radians), axis: [1, 0, 0])
        pivot.transform.rotation = yawRotation * pitchRotation
        
        // Update camera’s local position (height and zoom) using settings.cameraHeight.
        camera.transform.translation = SIMD3(0, settings.cameraHeight, cameraDistance)
        
        // Adjust skydome rotation if available.
        if let skydome = skydomeEntity {
            skydome.transform.rotation = yawRotation * skydomeBaseRotation
        }
    }
    
    // MARK: - Smooth Camera Animation

    /// Smoothly interpolates cameraAngle, cameraPitch, and cameraDistance toward their targets.
    ///
    /// - Parameter toPrint: Pass `true` to print debug statements; defaults to `false`.
    func startSmoothCameraAnimation(_ toPrint: Bool = false) {
        guard !isAnimatingCamera else {
            AppLogger.shared.debug("Animation already in progress. Skipping new call.", toPrint)
            return
        }
        isAnimatingCamera = true
        
        Task { @MainActor in
            lastUpdateTime = CACurrentMediaTime()
            while true {
                let currentTime = CACurrentMediaTime()
                let deltaTime = currentTime - lastUpdateTime
                // Clamp deltaTime to settings.maxDeltaTime (approx. 60 fps)
                let clampedDeltaTime = min(deltaTime, settings.maxDeltaTime)
                AppLogger.shared.debug("Animation Loop: deltaTime = \(deltaTime), clampedDeltaTime = \(clampedDeltaTime)", toPrint)
                
                // --- 1) Yaw Smoothing ---
                let angleDifference = targetCameraYaw.radians - cameraYaw.radians
                let maxDelta = settings.maxRotationSpeed * clampedDeltaTime
                let limitedDelta = max(-maxDelta, min(angleDifference, maxDelta))
                let t = min(1.0, clampedDeltaTime / settings.easingDuration)
                let easedT = smoothStep(t)
                let stabilizationFactor = 1.0 - settings.stabilizationFactorMultiplier * min(1.0, abs(angleDifference) / (maxDelta == 0 ? 1.0 : maxDelta))
                let easedDelta = limitedDelta * easedT * stabilizationFactor
                cameraYaw = Angle(radians: cameraYaw.radians + easedDelta)
                
                // --- 2) Pitch Smoothing ---
                let pitchDiff = targetCameraPitch.radians - cameraPitch.radians
                let maxPitchDelta = settings.maxRotationSpeed * clampedDeltaTime
                let limitedPitchDelta = max(-maxPitchDelta, min(pitchDiff, maxPitchDelta))
                let tPitch = min(1.0, clampedDeltaTime / settings.easingDuration)
                let easedTPitch = smoothStep(tPitch)
                let stabilizationFactorPitch = 1.0 - settings.stabilizationFactorMultiplier * min(1.0, abs(pitchDiff) / (maxPitchDelta == 0 ? 1.0 : maxPitchDelta))
                let finalPitchDelta = limitedPitchDelta * easedTPitch * stabilizationFactorPitch
                cameraPitch = Angle(radians: cameraPitch.radians + finalPitchDelta)
                
                // --- 3) Zoom Smoothing ---
                let distanceDiff = targetCameraDistance - cameraDistance
                let tZoom = min(1.0, clampedDeltaTime / settings.easingDuration)
                let easedTZoom = smoothStep(tZoom)
                let stabilizationFactorZoom = 1.0 - settings.stabilizationFactorMultiplier * min(1.0, abs(Double(distanceDiff)) / Double(settings.maxDistance - settings.minDistance))
                let zoomDelta = distanceDiff * Float(easedTZoom * stabilizationFactorZoom)
                cameraDistance += zoomDelta
                
                updateCameraTransform()
                
                // Break if differences are negligible.
                if abs(angleDifference) < settings.animationStopThreshold,
                   abs(pitchDiff) < settings.animationStopThreshold,
                   abs(distanceDiff) < Float(settings.animationStopThreshold) {
                    break
                }
                lastUpdateTime = currentTime
                try? await Task.sleep(nanoseconds: settings.animationFrameSleepNanoseconds)
            }
            isAnimatingCamera = false
            AppLogger.shared.debug("Animation loop ended.", toPrint)
        }
    }
    
    // MARK: - Skybox Setup

    /// Loads a skybox into the given camera content.
    ///
    /// - Parameters:
    ///   - content: The RealityViewCameraContent to which the skybox will be added.
    ///   - destination: A destination defining the skybox appearance (e.g. rotation).
    ///   - iblComponent: An ImageBasedLightComponent for image-based lighting.
    func loadSkybox(into content: RealityViewCameraContent,
                    for destination: Destination,
                    with iblComponent: ImageBasedLightComponent)
    {
        let rootEntity = Entity()

        // Load the skybox texture and apply it.
        rootEntity.addSkybox(for: destination)
        content.add(rootEntity)
        
        // Configure image-based lighting.
        rootEntity.components.set(iblComponent)
        rootEntity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: rootEntity))
        
        // Save a reference to the skydome.
        skydomeEntity = rootEntity
        
        // Store the base rotation derived from the destination.
        let baseAngle = Angle.degrees(destination.rotationDegrees)
        skydomeBaseRotation = simd_quatf(angle: Float(baseAngle.radians), axis: SIMD3(0, 1, 0))
    }
    
    // MARK: - Easing Helper

    /// Cubic ease-in-out (smoothstep) function.
    ///
    /// - Parameter t: A value between 0 and 1.
    /// - Returns: A smoothly interpolated value between 0 and 1.
    private func smoothStep(_ t: Double) -> Double {
        return t * t * (3 - 2 * t)
    }
}

// MARK: Codable Conformance (moved to extension)

extension CameraRotationComponent: Codable {
    enum CodingKeys: String, CodingKey {
        case dragStartAngle, dragBaseline, lastDragTranslation, lastDragUpdateTime, lastDeltaX, initialPinchDistance, lastPinchScale
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dragStartAngle = try container.decode(Angle.self, forKey: .dragStartAngle)
        dragBaseline = try container.decode(CGFloat.self, forKey: .dragBaseline)
        lastDragTranslation = try container.decode(CGSize.self, forKey: .lastDragTranslation)
        lastDragUpdateTime = try container.decode(TimeInterval.self, forKey: .lastDragUpdateTime)
        lastDeltaX = try container.decode(CGFloat.self, forKey: .lastDeltaX)
        initialPinchDistance = try container.decode(Float.self, forKey: .initialPinchDistance)
        lastPinchScale = try container.decode(CGFloat.self, forKey: .lastPinchScale)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dragStartAngle, forKey: .dragStartAngle)
        try container.encode(dragBaseline, forKey: .dragBaseline)
        try container.encode(lastDragTranslation, forKey: .lastDragTranslation)
        try container.encode(lastDragUpdateTime, forKey: .lastDragUpdateTime)
        try container.encode(lastDeltaX, forKey: .lastDeltaX)
        try container.encode(initialPinchDistance, forKey: .initialPinchDistance)
        try container.encode(lastPinchScale, forKey: .lastPinchScale)
    }
}
