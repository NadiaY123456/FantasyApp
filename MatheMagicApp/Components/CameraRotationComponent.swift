

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

    // NEW: For vertical drag
    public var dragStartPitch: Angle = .zero
    public var verticalDragBaseline: CGFloat = 0.0
    public var lastDeltaY: CGFloat = 0.0

    // MARK: Pinch (Zoom) State

    public var initialPinchDistance: Float = 0.0
    public var pinchBaseline: CGFloat = 1.0
    public var lastPinchScale: CGFloat = 1.0

    public init() {}
}

// MARK: - Camera Rotation System

class CameraRotationSystem: System {
    @MainActor private static let query = EntityQuery(where: .has(CameraRotationComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    static var dependencies: [SystemDependency] { [] }

    func update(context: SceneUpdateContext) {
        let gameModelView = GameModelView.shared
        let currentTime = CACurrentMediaTime()
        
        processDrag(in: context, gameModelView: gameModelView, currentTime: currentTime)
        processPinch(in: context, gameModelView: gameModelView)
    }
    
    // MARK: - Drag Processing
    
    /// Processes drag (rotation & pitch) updates.
    @MainActor
    private func processDrag(in context: SceneUpdateContext, gameModelView: GameModelView, currentTime: TimeInterval) {
        let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        if gameModelView.isDragging, let currentTranslation = gameModelView.rawDragTranslation {
            for entity in entities {
                var gestureState = entity.components[CameraRotationComponent.self] ?? CameraRotationComponent()
                let dt = currentTime - gestureState.lastDragUpdateTime
                
                processHorizontalDrag(for: &gestureState, currentTranslation: currentTranslation, deltaTime: dt, gameModelView: gameModelView)
                processVerticalDrag(for: &gestureState, currentTranslation: currentTranslation, gameModelView: gameModelView) // DO NOT DELETE THIS COMMENT!
                
                gestureState.lastDragTranslation = currentTranslation
                gestureState.lastDragUpdateTime = currentTime
                entity.components.set(gestureState)
                
                gameModelView.camera.startSmoothCameraAnimation()
            }
        } else {
            // Lock in final values when not dragging.
            gameModelView.camera.targetCameraYaw = gameModelView.camera.cameraYaw
            gameModelView.camera.targetCameraPitch = gameModelView.camera.cameraPitch
            gameModelView.camera.targetCameraDistance = gameModelView.camera.cameraDistance
            
            for entity in entities {
                var gestureState = entity.components[CameraRotationComponent.self] ?? CameraRotationComponent()
                resetDragState(&gestureState, currentTime: currentTime, gameModelView: gameModelView)
                entity.components.set(gestureState)
            }
        }
    }
    
    /// Processes horizontal drag to update yaw.
    @MainActor
    private func processHorizontalDrag(for gestureState: inout CameraRotationComponent,
                                       currentTranslation: CGSize,
                                       deltaTime dt: TimeInterval,
                                       gameModelView: GameModelView)
    {
        // Calculate the change in x position.
        let deltaX = currentTranslation.width - gestureState.lastDragTranslation.width
        
        // Get dead zone and time threshold from settings.
        let deadZone = gameModelView.camera.settings.horizontalDragDeadZone
        let timeThreshold = gameModelView.camera.settings.horizontalDragTimeThreshold
        
        // If the change is too small or if too much time passed since the last update, reset the baseline.
        if abs(deltaX) < deadZone || dt > timeThreshold {
            gameModelView.camera.targetCameraYaw = gameModelView.camera.cameraYaw
            gestureState.dragStartAngle = gameModelView.camera.cameraYaw
            gestureState.dragBaseline = currentTranslation.width
        } else {
            // If the direction of the drag changes (and the movement is significant), reset the baseline.
            if gestureState.lastDeltaX * deltaX < 0 && abs(deltaX) > deadZone {
                gestureState.dragStartAngle = gameModelView.camera.cameraYaw
                gestureState.dragBaseline = currentTranslation.width
            }
            
            // Calculate the effective drag beyond the baseline.
            let effectiveDrag = currentTranslation.width - gestureState.dragBaseline
            
            // Update the target yaw using the effective drag multiplied by the rotation sensitivity.
            gameModelView.camera.targetCameraYaw = gestureState.dragStartAngle +
                Angle(radians: -Double(effectiveDrag) * gameModelView.camera.settings.rotationSensitivity)
        }
        
        gestureState.lastDeltaX = deltaX
    }

    /// Processes vertical drag to update pitch only (with reversed direction),
    /// leaving the target zoom (set by pinch) unchanged.
    @MainActor
    private func processVerticalDrag(for gestureState: inout CameraRotationComponent,
                                     currentTranslation: CGSize,
                                     gameModelView: GameModelView)
    {
        let currentTime = CACurrentMediaTime()
        let dt = currentTime - gestureState.lastDragUpdateTime
        let deltaY = currentTranslation.height - gestureState.lastDragTranslation.height

        // Use a minimal threshold for vertical movement, similar to horizontal.
        if abs(deltaY) < 1.0 || dt > 0.1 {
            // If movement is minimal or there's been a pause, "lock" the pitch.
            gameModelView.camera.targetCameraPitch = gameModelView.camera.cameraPitch
            gestureState.dragStartPitch = gameModelView.camera.cameraPitch
            gestureState.verticalDragBaseline = currentTranslation.height
        } else {
            // If the direction of drag changes (and the movement is significant), reset the baseline.
            if gestureState.lastDeltaY * deltaY < 0 && abs(deltaY) > 1.0 {
                gestureState.dragStartPitch = gameModelView.camera.cameraPitch
                gestureState.verticalDragBaseline = currentTranslation.height
            }
            
            let effectiveDrag = currentTranslation.height - gestureState.verticalDragBaseline
            let pitchSensitivity = 0.1
            // (An upward swipe (positive deltaY) will decrease pitch.)
            let newPitchDegrees = gestureState.dragStartPitch.degrees + Double(effectiveDrag) * pitchSensitivity

            // Clamp the pitch to the allowed range.
            let clampedPitchDegrees = min(max(newPitchDegrees,
                                              gameModelView.camera.settings.minPitch.degrees),
                                          gameModelView.camera.settings.maxPitch.degrees)
            gameModelView.camera.targetCameraPitch = .degrees(clampedPitchDegrees)
        }
        gestureState.lastDeltaY = deltaY
    }

    /// Resets the drag state when no drag is occurring.
    @MainActor
    private func resetDragState(_ gestureState: inout CameraRotationComponent, currentTime: TimeInterval, gameModelView: GameModelView) {
        gestureState.lastDragTranslation = .zero
        gestureState.lastDeltaX = 0.0
        gestureState.dragBaseline = 0.0

        // NEW: Reset vertical drag state
        gestureState.lastDeltaY = 0.0
        gestureState.verticalDragBaseline = 0.0
        gestureState.dragStartPitch = gameModelView.camera.cameraPitch // if you have access or pass it in

        gestureState.lastDragUpdateTime = currentTime
    }
    
    // MARK: - Pinch Processing
    
    /// Processes pinch (zoom) updates.

    @MainActor
    private func processPinch(in context: SceneUpdateContext, gameModelView: GameModelView) {
        let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        // A small threshold to decide if the user has really moved their fingers.
        let pinchThreshold: CGFloat = 0.001

        for entity in entities {
            var gestureState = entity.components[CameraRotationComponent.self] ?? CameraRotationComponent()

            if gameModelView.isPinching {
                // At the start of a pinch gesture, record initial values.
                if gestureState.lastPinchScale == 1.0 {
                    gestureState.initialPinchDistance = gameModelView.camera.cameraDistance
                    gestureState.pinchBaseline = gameModelView.rawPinchScale
                }

                let scaleChange = gameModelView.rawPinchScale - gestureState.lastPinchScale

                // Only update zoom if the scale change exceeds the threshold.
                if abs(scaleChange) >= pinchThreshold {
                    // Compute the effective scale and new distance.
                    let effectiveScale = gameModelView.rawPinchScale / gestureState.pinchBaseline
                    let newDistance = gestureState.initialPinchDistance / Float(effectiveScale)
                    // Clamp newDistance to allowed zoom range.
                    let clampedDistance = min(gameModelView.camera.settings.maxDistance,
                                              max(gameModelView.camera.settings.minDistance, newDistance))
                    gameModelView.camera.targetCameraDistance = clampedDistance
                    // Update the lastPinchDistance so that updateCameraTransform uses the latest value.
                    gameModelView.camera.lastPinchDistance = clampedDistance
                    gameModelView.camera.startSmoothCameraAnimation()
                }
                // Always update the last pinch scale.
                gestureState.lastPinchScale = gameModelView.rawPinchScale

            } else {
                // On pinch release, simply reset the pinch state.
                if gestureState.lastPinchScale != 1.0 {
                    gestureState.lastPinchScale = 1.0
                    gestureState.initialPinchDistance = gameModelView.camera.lastPinchDistance
                    gestureState.pinchBaseline = 1.0
                }
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
        var minPitch: Angle = .degrees(-89) // e.g. 45° from above
        var maxPitch: Angle = .degrees(89) // e.g. 80° from below
            
        /// Zoom boundaries
        var minDistance: Float = 1.0
        var maxDistance: Float = 6.0
            
        /// Offset for the pivot (e.g. center on a character’s knees rather than chest)
        /// pivot is the center point of camera rotation. by default, it is set at character position.
        var pivotOffset: SIMD3<Float> = SIMD3(0, 1.5, 0)
            
        // MARK: Parameters that affect horizontal rotation speed
            
        /// Smoothing and damping parameters
        var maxRotationSpeed: Double = 10 * .pi // Maximum allowed rotation speed (radians per second)
            
        /// Sensitivity parameters for camera motions
        var rotationSensitivity: Double = 0.75 // Controls how fast the camera rotates based on drag
        var zoomSensitivity: Float = 1.5 // Controls how much zoom occurs per pinch
        
        // Horizontal drag dead zone. Movements smaller than this will be ignored.
        var horizontalDragDeadZone: CGFloat = 2.0
        
        /// The maximum allowed delta time (in seconds) before the drag baseline is reset.
        var horizontalDragTimeThreshold: Double = 0.1

        /// Easing duration for interpolation (in seconds)
        var easingDuration: Double = 0.075 // higher -> slower zoom and rotation speed

        // MARK: Additional Configurable Parameters

        /// Vertical offset for the camera’s local translation relative to the pivot.
        var cameraHeight: Float = 2

        /// Maximum allowed delta time per frame (in seconds) to clamp animation steps (approx. 60 fps).
        var maxDeltaTime: Double = 0.016

        /// Multiplier applied to the stabilization factor in smoothing calculations to reduce overshooting.
        var stabilizationFactorMultiplier: Double = 0.5

        /// Threshold below which differences are considered negligible, stopping the animation loop.
        var animationStopThreshold: Double = 0.001

        /// Sleep duration between animation frames in nanoseconds (approx. 60 fps).
        var animationFrameSleepNanoseconds: UInt64 = 16_000_000
            
        // Minimum allowed world Y position for the camera. Used for vertical rotation, so camera does not go underground.
        var minCameraHeight: Float = 0.1
        //        var verticalSafetyFactor: Float = 0.5 // Scales the effect of the targetDistance on the vertical offset.  (from 0 to 1) For example, a value of 0.5 reduces the downward pull by half. (If you’d like even less interference, try an even smaller value.)
    }

    // MARK: Camera State Properties

    /// The current values are what the camera is actually using at any given frame. The target values are where you eventually want the camera to end up.
    
    /// Should have the same default values to avoid a jump in the beginning
    var cameraDistance: Float = 4.0
    var targetCameraDistance: Float = 4.0
    var lastPinchDistance: Float = 4.0 /// Final pinch-based distance so we can "return" to it when swiping up.
    
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
    func addCamera(to content: RealityViewCameraContent, relativeTo tracked: Entity, toPrint: Bool = true) {
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
        
        AppLogger.shared.debug("Camera world Position: \(camera.transform.translation + pivot.transform.translation), and cameraPivot: \(pivot.transform.translation)", toPrint)
    }
    
    // MARK: - Camera Transform Update

    func updateCameraTransform(toPrint: Bool = true) {
        guard let pivot = cameraPivot, let camera = cameraEntity else { return }
        
        // Reset the pivot rotation to ensure no roll (z-axis rotation)
        pivot.transform.rotation = simd_quatf(angle: 0, axis: SIMD3(0, 0, 1))
        
        // Update pivot position based on the tracked entity.
        if let tracked = trackedEntity {
            pivot.transform.translation = tracked.transform.translation + settings.pivotOffset
        }
        
        let pivotWorldPosition = pivot.transform.translation
        let yaw = Float(cameraYaw.radians)
        let pitch = Float(cameraPitch.radians)
        
        // Use lastPinchDistance as the "original" desired distance from the pivot.
        // (This value is updated when the pinch gesture ends.)
        var desiredDistance = lastPinchDistance
        
        // Calculate the tentative world Y position of the camera using the desiredDistance.
        let tentativeY = pivotWorldPosition.y + desiredDistance * sin(pitch)
        
        // If the tentative Y is below the allowed minimum, adjust desiredDistance so that
        // the camera’s Y exactly equals settings.minCameraHeight.
        if tentativeY < settings.minCameraHeight {
            // Avoid division by zero; if sin(pitch) is very close to zero, skip adjustment.
            if abs(sin(pitch)) > 0.0001 {
                desiredDistance = (settings.minCameraHeight - pivotWorldPosition.y) / sin(pitch)
            }
        } else {
            // Not binding; revert to the original desired distance.
            desiredDistance = lastPinchDistance
        }
        
        // Compute the offset using the (possibly adjusted) desiredDistance.
        let offset = SIMD3<Float>(
            desiredDistance * cos(pitch) * sin(yaw),
            desiredDistance * sin(pitch),
            desiredDistance * cos(pitch) * cos(yaw)
        )
        
        let cameraWorldPosition = pivotWorldPosition + offset
        // Set camera translation relative to the pivot.
        camera.transform.translation = cameraWorldPosition - pivotWorldPosition
        
        // Compute a look-at rotation for the camera that locks roll.
        let forward = simd_normalize(pivotWorldPosition - cameraWorldPosition)
        let upWorld = SIMD3<Float>(0, 1, 0) // fixed up vector
        let right = simd_normalize(simd_cross(forward, upWorld))
        let up = simd_cross(right, forward)
        let rotationMatrix = float3x3(columns: (right, up, -forward))
        camera.transform.rotation = simd_quatf(rotationMatrix)
        
        // Update the skydome rotation if available.
        if let skydome = skydomeEntity {
            let yawRotation = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
            skydome.transform.rotation = yawRotation * skydomeBaseRotation
        }
        
        AppLogger.shared.debug(
            "Camera World Position: \(cameraWorldPosition) | Pivot Position: \(pivotWorldPosition) | Yaw: \(cameraYaw.degrees)° | Pitch: \(cameraPitch.degrees)°",
            toPrint
        )
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
                   abs(distanceDiff) < Float(settings.animationStopThreshold)
                {
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
    
    /// Computes an adjusted camera distance based on current pitch and pivot position
    /// to ensure the camera stays above ground. If the target distance (set by pinch)
    /// would cause ground clipping, we override it with a smaller safe distance.
    private func adjustedCameraDistance(toPrint: Bool = true) -> Float {
        let pivotY = cameraPivot?.transform.translation.y ?? 0
        let safetyMargin = settings.minCameraHeight
        let pitch = Float(cameraPitch.radians)
        let pitchDegrees = cameraPitch.degrees
        let targetDistance = targetCameraDistance

        // Compute the world-space Y position of the camera.
        let worldCameraY = pivotY + settings.cameraHeight * cos(pitch) - targetDistance * sin(pitch)
        
        // Log the starting parameters.
        AppLogger.shared.debug("AdjCam: pivotY=\(pivotY), pitch=\(pitchDegrees)°, targetDist=\(targetDistance), worldY=\(worldCameraY)", toPrint)

        if pitch > 0 {
            if worldCameraY < safetyMargin {
                let computedSafeDistance = (pivotY + settings.cameraHeight * cos(pitch) - safetyMargin) / sin(pitch)
                let safeDistance = max(0, computedSafeDistance)
                let effectiveDistance = min(targetDistance, safeDistance)
                AppLogger.shared.debug("AdjCam: worldY=\(worldCameraY) < \(safetyMargin) → safeDist=\(safeDistance), effectiveDist=\(effectiveDistance)", toPrint)
                return effectiveDistance
            }
        }
        
        AppLogger.shared.debug("AdjCam: No adjustment needed; using targetDist", toPrint)
        return targetDistance
    }
}

// MARK: Codable Conformance (moved to extension)

extension CameraRotationComponent: Codable {
    enum CodingKeys: String, CodingKey {
        case dragStartAngle, dragBaseline, lastDragTranslation, lastDragUpdateTime, lastDeltaX
        case dragStartPitch, verticalDragBaseline, lastDeltaY
        case initialPinchDistance, lastPinchScale
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dragStartAngle = try container.decode(Angle.self, forKey: .dragStartAngle)
        dragBaseline = try container.decode(CGFloat.self, forKey: .dragBaseline)
        lastDragTranslation = try container.decode(CGSize.self, forKey: .lastDragTranslation)
        lastDragUpdateTime = try container.decode(TimeInterval.self, forKey: .lastDragUpdateTime)
        lastDeltaX = try container.decode(CGFloat.self, forKey: .lastDeltaX)
        
        // New vertical drag properties.
        dragStartPitch = try container.decode(Angle.self, forKey: .dragStartPitch)
        verticalDragBaseline = try container.decode(CGFloat.self, forKey: .verticalDragBaseline)
        lastDeltaY = try container.decode(CGFloat.self, forKey: .lastDeltaY)
        
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
        
        // New vertical drag properties.
        try container.encode(dragStartPitch, forKey: .dragStartPitch)
        try container.encode(verticalDragBaseline, forKey: .verticalDragBaseline)
        try container.encode(lastDeltaY, forKey: .lastDeltaY)
        
        try container.encode(initialPinchDistance, forKey: .initialPinchDistance)
        try container.encode(lastPinchScale, forKey: .lastPinchScale)
    }
}
