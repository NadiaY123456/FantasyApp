//
//  CameraRotationComponent.swift
//  MatheMagic
//

import RealityKit
import SwiftUI

/// Attach this component to the camera (or its pivot) so that the gesture system can
/// update its rotation/zoom based on drag input.
import RealityKit
import SwiftUI

/// A component to store drag & pinch state for camera updates.
public struct CameraRotationComponent: Component, Codable {
    // Drag-related state.
    public var dragStartAngle: Angle = .zero
    public var dragBaseline: CGFloat = 0.0
    public var lastDragTranslation: CGSize = .zero
    public var lastDragUpdateTime: TimeInterval = CACurrentMediaTime()
    public var lastDeltaX: CGFloat = 0.0
    
    // Pinch (zoom) state.
    public var initialPinchDistance: Float = 0.0
    public var lastPinchScale: CGFloat = 1.0

    public init() {}

    enum CodingKeys: String, CodingKey {
        case dragStartAngle, dragBaseline, lastDragTranslation, lastDragUpdateTime, lastDeltaX, initialPinchDistance, lastPinchScale
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dragStartAngle = try container.decode(Angle.self, forKey: .dragStartAngle) //Instance method 'decode(_:forKey:)' requires that 'Angle' conform to 'Decodable'
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


import RealityKit

class CameraRotationSystem: System {
    @MainActor private static let query = EntityQuery(where: .has(CameraRotationComponent.self))

    required init(scene: RealityKit.Scene) {}

    static var dependencies: [SystemDependency] { [] }

    func update(context: SceneUpdateContext) {
        let sharedView = GameModelView.shared

        // Process drag (rotation & pitch) updates.
        if sharedView.isDragging, let currentTranslation = sharedView.rawDragTranslation {
            let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
            for entity in entities {
                var gestureState = entity.components[CameraRotationComponent.self] ?? CameraRotationComponent()
                let now = CACurrentMediaTime()
                let dt = now - gestureState.lastDragUpdateTime

                // --- Horizontal (Yaw) Logic ---
                let deltaX = currentTranslation.width - gestureState.lastDragTranslation.width
                if abs(deltaX) < 1.0 || dt > 0.1 {
                    sharedView.camera.targetCameraAngle = sharedView.camera.cameraAngle
                    gestureState.dragStartAngle = sharedView.camera.cameraAngle
                    gestureState.dragBaseline = currentTranslation.width
                } else {
                    if gestureState.lastDeltaX * deltaX < 0 && abs(deltaX) > 1.0 {
                        gestureState.dragStartAngle = sharedView.camera.cameraAngle
                        gestureState.dragBaseline = currentTranslation.width
                    }
                    let effectiveDrag = currentTranslation.width - gestureState.dragBaseline
                    sharedView.camera.targetCameraAngle = gestureState.dragStartAngle +
                        Angle(radians: -Double(effectiveDrag) * sharedView.camera.rotationSensitivity)
                }
                gestureState.lastDeltaX = deltaX

                // --- Vertical (Pitch & Zoom) Logic ---
                let deltaY = currentTranslation.height - gestureState.lastDragTranslation.height
                if abs(deltaY) > 1.0 {
                    if deltaY > 0 {
                        // Swiping downward: zoom in and tilt upward.
                        let newDistance = sharedView.camera.targetCameraDistance - Float(deltaY) * 0.01
                        sharedView.camera.targetCameraDistance = max(sharedView.camera.minDistance, newDistance)
                        
                        let pitchUp = Double(deltaY) * 0.1
                        let nextPitch = sharedView.camera.targetCameraPitch.degrees + pitchUp
                        sharedView.camera.targetCameraPitch = .degrees(min(sharedView.camera.maxPitch.degrees, nextPitch))
                    } else {
                        // Swiping upward: restore zoom (if needed) then tilt downward.
                        if sharedView.camera.targetCameraDistance < sharedView.camera.lastPinchDistance {
                            let newDistance = sharedView.camera.targetCameraDistance + Float(-deltaY) * 0.01
                            sharedView.camera.targetCameraDistance = min(sharedView.camera.lastPinchDistance, newDistance)
                        } else {
                            let pitchDown = Double(deltaY) * 0.1
                            let nextPitch = sharedView.camera.targetCameraPitch.degrees + pitchDown
                            sharedView.camera.targetCameraPitch = .degrees(max(sharedView.camera.minPitch.degrees, nextPitch))
                        }
                    }
                }
                
                gestureState.lastDragTranslation = currentTranslation
                gestureState.lastDragUpdateTime = now
                entity.components.set(gestureState)
                
                sharedView.camera.startSmoothCameraAnimation()
            }
        } else {
            // No drag—lock in final values.
            sharedView.camera.targetCameraAngle = sharedView.camera.cameraAngle
            sharedView.camera.targetCameraPitch = sharedView.camera.cameraPitch
            sharedView.camera.targetCameraDistance = sharedView.camera.cameraDistance

            let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
            for entity in entities {
                var gestureState = entity.components[CameraRotationComponent.self] ?? CameraRotationComponent()
                gestureState.lastDragTranslation = .zero
                gestureState.lastDeltaX = 0.0
                gestureState.dragBaseline = 0.0
                gestureState.lastDragUpdateTime = CACurrentMediaTime()
                entity.components.set(gestureState)
            }
        }
        
        // Process pinch (zoom) updates.
        let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        for entity in entities {
            var gestureState = entity.components[CameraRotationComponent.self] ?? CameraRotationComponent()
            
            if sharedView.isPinching {
                if gestureState.lastPinchScale == 1.0 {
                    gestureState.initialPinchDistance = sharedView.camera.cameraDistance
                }
                let scale = Float(sharedView.rawPinchScale)
                let newDistance = gestureState.initialPinchDistance * (1 - (scale - 1) * sharedView.camera.zoomSensitivity)
                sharedView.camera.targetCameraDistance = min(sharedView.camera.maxDistance,
                                                             max(sharedView.camera.minDistance, newDistance))
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




