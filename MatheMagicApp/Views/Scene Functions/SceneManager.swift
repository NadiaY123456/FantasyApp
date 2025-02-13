//
//  SceneManager.swift
//  MatheMagic
//

import RealityKit
import SwiftUI

class SceneManager: ObservableObject {
    // MARK: - Camera Control Properties

    @Published var cameraAngle: Angle = .zero
    @Published var targetCameraAngle: Angle = .zero
    @Published var cameraDistance: Float = 7.0
    @Published var targetCameraDistance: Float = 7.0

    // MARK: - Pitch Control

    @Published var cameraPitch: Angle = .degrees(0)
    @Published var targetCameraPitch: Angle = .degrees(0)

    // Clamp the pitch so you can’t spin the camera 360° vertically
    let minPitch: Angle = .degrees(-45) // e.g. 45° from above
    let maxPitch: Angle = .degrees(80) // e.g. 80° from below

    // Store the final pinch-based distance so we can "return" to it when swiping up
    var lastPinchDistance: Float = 7.0

    let minDistance: Float = 2.0
    let maxDistance: Float = 12.0
    /// Lower the zoom center by 0.5 m (so it centers on Flash’s knees rather than chest)
    let pivotOffset: SIMD3<Float> = SIMD3(0, -0.5, 0)

    // === Smoothing and damping factors ===:

    // - smoothingFactor: base smoothing constant
    let smoothingFactor: Float = 0.15 // higher value -> faster convergence (less lingering motion)

    // - dampingFactor: extra factor to prevent overshoot
    let dampingFactor: Float = 1.0 // higher value -> More damping to stop rotation quickly

    //  - Maximum allowed change in rotation (radians per second)
    var maxRotationSpeed: Double = 6.0 // higher value -> rotation feels snappier

    // Sensitivity parameters for motion sickness reduction
    var rotationSensitivity: Double = 0.01 // Adjust to control how fast the camera rotates
    var zoomSensitivity: Float = 1.0 // Adjust to control how much zoom occurs per pinch

    // Easing duration (in seconds) to determine how quickly interpolation should occur.
    var easingDuration: Double = 0.1

    private var isAnimatingCamera = false
    private var lastUpdateTime: TimeInterval = CACurrentMediaTime()

    // MARK: - Camera and Tracking Entities

    var cameraPivot: Entity?
    var cameraEntity: Entity?
    /// The entity the camera orbits around (e.g. a character)
    var trackedEntity: Entity?

    /// The skydome entity used for the skybox.
    var skydomeEntity: Entity?
    /// The initial (base) rotation for the skydome, based on the destination.
    var skydomeBaseRotation: simd_quatf = .init(angle: 0, axis: SIMD3(0, 1, 0))

    /// Adds a camera that orbits around the tracked character.
    func addCamera(to content: RealityViewCameraContent, relativeTo tracked: Entity) {
        trackedEntity = tracked

        // Create a pivot at the tracked character’s position.
        let pivot = Entity()
        pivot.transform.translation = tracked.transform.translation + pivotOffset

        content.add(pivot)
        cameraPivot = pivot

        // Create the camera entity.
        let camera = Entity()
        camera.components.set(PerspectiveCameraComponent())
        // Set the initial position (height and zoom).
        camera.transform.translation = SIMD3(0, 1.6, cameraDistance)
        pivot.addChild(camera)
        cameraEntity = camera
        // Immediately update the camera transform so the pivot is in the correct place.
        updateCameraTransform()
    }

    /// Updates the camera transform by:
    /// - Resetting the pivot’s position to the tracked character’s location.
    /// - Applying the current rotation and zoom.
    /// - Adding a slight tilt to the camera.
    /// - Fixing the skydome by rotating it opposite to the camera's rotation.
    func updateCameraTransform() {
        guard let pivot = cameraPivot, let camera = cameraEntity else { return }

        // Follow the tracked entity
        if let tracked = trackedEntity {
            pivot.transform.translation = tracked.transform.translation + pivotOffset
        }

        // Combine yaw (cameraAngle) and pitch (cameraPitch)
        let yawRotation = simd_quatf(angle: Float(cameraAngle.radians), axis: [0, 1, 0])
        let pitchRotation = simd_quatf(angle: Float(cameraPitch.radians), axis: [1, 0, 0])
        pivot.transform.rotation = yawRotation * pitchRotation


        // If you want a slight downward tilt from the camera’s own local transform,
        // you can keep or remove the small rotation below. For now, you can remove it
        // if you are explicitly controlling pitch:
        // camera.transform.rotation = simd_quatf(angle: Float.pi * 0.05, axis: SIMD3(1, 0, 0))

        // Update camera’s local position (height + zoom)
        camera.transform.translation = SIMD3(0, 1.6, cameraDistance)

        // Fix the skydome’s rotation if needed
        if let skydome = skydomeEntity {
            skydome.transform.rotation = yawRotation * skydomeBaseRotation
        }
    }

    /// Starts an animation loop to smoothly interpolate the camera’s angle and distance.
    func startSmoothCameraAnimation() {
        guard !isAnimatingCamera else {
            AppLogger.shared.debug("Animation already in progress. Skipping new call.")
            return
        }
        isAnimatingCamera = true

        Task { @MainActor in
            lastUpdateTime = CACurrentMediaTime()
            while true {
                let currentTime = CACurrentMediaTime()
                let deltaTime = currentTime - lastUpdateTime
                let clampedDeltaTime = min(deltaTime, 0.016) // Clamp to ~16ms maximum
                AppLogger.shared.debug("Animation Loop: deltaTime = \(deltaTime), clampedDeltaTime = \(clampedDeltaTime)")

                // 1) Yaw smoothing
                let angleDifference = targetCameraAngle.radians - cameraAngle.radians
                let maxDelta = maxRotationSpeed * clampedDeltaTime
                let limitedDelta = max(-maxDelta, min(angleDifference, maxDelta))
                let t = min(1.0, clampedDeltaTime / easingDuration)
                let easedT = smoothStep(t)
                let stabilizationFactor = 1.0 - 0.5 * min(1.0, abs(angleDifference) / (maxDelta == 0 ? 1.0 : maxDelta))
                let easedDelta = limitedDelta * easedT * stabilizationFactor
                cameraAngle = Angle(radians: cameraAngle.radians + easedDelta)

                // 2) Pitch smoothing
                let pitchDiff = targetCameraPitch.radians - cameraPitch.radians
                let maxPitchDelta = maxRotationSpeed * clampedDeltaTime
                let limitedPitchDelta = max(-maxPitchDelta, min(pitchDiff, maxPitchDelta))
                let tPitch = min(1.0, clampedDeltaTime / easingDuration)
                let easedTPitch = smoothStep(tPitch)
                let stabilizationFactorPitch = 1.0 - 0.5 * min(1.0, abs(pitchDiff) / (maxPitchDelta == 0 ? 1.0 : maxPitchDelta))
                let finalPitchDelta = limitedPitchDelta * easedTPitch * stabilizationFactorPitch
                cameraPitch = Angle(radians: cameraPitch.radians + finalPitchDelta)

                // 3) Zoom smoothing
                let distanceDiff = targetCameraDistance - cameraDistance
                let tZoom = min(1.0, clampedDeltaTime / easingDuration)
                let easedTZoom = smoothStep(tZoom)
                let stabilizationFactorZoom = 1.0 - 0.5 * min(1.0, abs(Double(distanceDiff)) / Double(maxDistance - minDistance))
                let zoomDelta = distanceDiff * Float(easedTZoom * stabilizationFactorZoom)
                cameraDistance += zoomDelta

                updateCameraTransform()

                // If everything is close enough, break
                if abs(angleDifference) < 0.001 && abs(distanceDiff) < 0.001 && abs(pitchDiff) < 0.001 {
                    break
                }
                lastUpdateTime = currentTime

                try? await Task.sleep(nanoseconds: 16000000) // ~60 fps
            }
            isAnimatingCamera = false
            AppLogger.shared.debug("Animation loop ended.")
        }
    }

    // MARK: Lights and Skyboxes

    func loadSkybox(into content: RealityViewCameraContent, for destination: Destination, with iblComponent: ImageBasedLightComponent) {
        let rootEntity = Entity()

        // Load the skybox texture and apply it to the rootEntity.
        rootEntity.addSkybox(for: destination)
        content.add(rootEntity)

        // Set the ImageBasedLightComponent to the rootEntity.
        rootEntity.components.set(iblComponent)
        rootEntity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: rootEntity))

        // Save a reference to the skydome.
        skydomeEntity = rootEntity

        // Store the base rotation (defined by the destination).
        let baseAngle = Angle.degrees(destination.rotationDegrees)
        skydomeBaseRotation = simd_quatf(angle: Float(baseAngle.radians), axis: SIMD3(0, 1, 0))
    }

    func addPointLight(to entity: Entity) {
        let pointLight = PointLightComponent(
            color: .white,
            intensity: 26963.76,
            attenuationRadius: 10.0
        )
        let lightEntity = Entity()
        lightEntity.components.set(pointLight)
        lightEntity.transform.translation = simd_float3(0.5, 0.5, 0)
        entity.addChild(lightEntity)
    }

    // MARK: - (A) Add a Directional Light with Shadows

    func addDirectionalLight(to parent: Entity) {
        // Create the directional light component.
        let directionalLight = DirectionalLightComponent(color: .white, intensity: 15000)
        // Create the shadow component using the new API.
        let shadow = DirectionalLightComponent.Shadow(
            shadowProjection: .automatic(maximumDistance: 50),
            depthBias: 1.0
        )
        // Create an entity and add both components.
        let directionalLightEntity = Entity()
        directionalLightEntity.components.set([directionalLight, shadow])
        // Rotate the light entity so that its forward direction ([0, 0, -1]) points downward (45°).
        directionalLightEntity.transform.rotation = simd_quatf(angle: .pi / 4, axis: [1, 0, 0])
        parent.addChild(directionalLightEntity)
    }

    // MARK: - (B) Use Environment Lighting (IBL) and Skybox

    func addImageBasedLight(name: String = "ImageBasedLight") async throws -> ImageBasedLightComponent {
        do {
            let resource = try await EnvironmentResource(named: name)

            let iblComponent = ImageBasedLightComponent(source: .single(resource), intensityExponent: 0.25)
            return iblComponent
        } catch {
            AppLogger.shared.error("Error: Failed to add ImageBasedLight")
            throw error // Propagate the error to the caller
        }
    }

    func addContentWithLight(entity: Entity, iblComponent: ImageBasedLightComponent) {
//        entity.components.set(iblComponent) // This one to emit light?
        entity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: entity)) // This one to receive light
        spaceOrigin.addChild(entity)
    }

    // Easing helper using a smoothstep function
    private func smoothStep(_ t: Double) -> Double {
        // Cubic ease-in-out (smoothstep) function: maps 0→1 input to a smooth 0→1 output.
        return t * t * (3 - 2 * t)
    }
}
