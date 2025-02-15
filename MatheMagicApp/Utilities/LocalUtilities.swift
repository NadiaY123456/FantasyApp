//
//  LocalUtilities.swift
//  MahoStart
//
//  Created by Mahmut Yilmaz on 2/24/24.
//

import Foundation
import SwiftUI
import RealityKit
import RealityKitContent
import CoreLib


struct LoadUtilities {
    
    @MainActor
    static func loadFromRealityComposerPro(named entityName: String, fromSceneNamed sceneName: String) async -> Entity? {
        var entity: Entity?
        do {
            let scene = try await Entity(named: sceneName, in: realityKitContentBundle)
            entity = scene.findEntity(named: entityName)
        } catch {
            AppLogger.shared.error("Error loading \(entityName) from scene \(sceneName): \(error.localizedDescription)")
        }
        return entity
    }
    
    @MainActor
    static func getEntityWithName (name: String, scene: Entity ) -> some Entity {
        if let localEntity = scene.findEntity(named: name) {
//            localEntity.generateCollisionShapes(recursive: false)
//            localEntity.components.set(InputTargetComponent())
            localEntity.components.set(HoverEffectComponent())
            return localEntity
        } else {
            fatalError("Cannot find entity: \(name)")
        }
    }
}

// Function to extract Euler angles from simd_float4x4 matrix
func extractEulerAngles(from matrix: simd_float4x4) -> (roll: Float, pitch: Float, yaw: Float) {
    let sy = sqrt(matrix.columns.0.x * matrix.columns.0.x + matrix.columns.1.x * matrix.columns.1.x)
    let singular = sy < 1e-6 // If

    var x, y, z: Float
    if !singular {
        x = atan2(matrix.columns.2.y, matrix.columns.2.z)
        y = atan2(-matrix.columns.2.x, sy)
        z = atan2(matrix.columns.1.x, matrix.columns.0.x)
    } else {
        x = atan2(-matrix.columns.1.z, matrix.columns.1.y)
        y = atan2(-matrix.columns.2.x, sy)
        z = 0
    }

    // Convert radians to degrees
    let roll =  -1 * x * 180 / .pi
    let pitch = -1 * y * 180 / .pi
    let yaw = -1 * z * 180 / .pi

    return (roll, pitch, yaw)
}

// Function to extract Euler angles from entity simd_float4x4 matrix
func extractEntityOrientationAngles(from entity: Entity) -> (roll: Float, pitch: Float, yaw: Float) {
    let matrix = entity.transform.matrix
    let sy = sqrt(matrix.columns.0.x * matrix.columns.0.x + matrix.columns.1.x * matrix.columns.1.x)
    let singular = sy < 1e-6 // If

    var x, y, z: Float
    if !singular {
        x = atan2(matrix.columns.2.y, matrix.columns.2.z)
        y = atan2(-matrix.columns.2.x, sy)
        z = atan2(matrix.columns.1.x, matrix.columns.0.x)
    } else {
        x = atan2(-matrix.columns.1.z, matrix.columns.1.y)
        y = atan2(-matrix.columns.2.x, sy)
        z = 0
    }

    // Convert radians to degrees
    let roll =  -1 * x
    let pitch = -1 * y
    let yaw = -1 * z 

    return (roll, pitch, yaw)
}

func pr<T>(_ value: T, variableName: String) {
    AppLogger.shared.info("\(variableName) = \(value)")
}



func createSphere(color: UIColor = .blue, radius: Float = 1.0, position: SIMD3<Float> = [0, 0, 0]) -> ModelEntity {
    // Generate the sphere mesh with the specified radius
    let mesh = MeshResource.generateSphere(radius: radius)
    
    // Create a simple material with the specified color
    let material = SimpleMaterial(color: color, isMetallic: false)
    
    // Create a ModelEntity with the generated mesh and material
    let modelEntity = ModelEntity(mesh: mesh, materials: [material])
    
    // Set the position of the ModelEntity
    modelEntity.position = position
    
    
    return modelEntity
}

//func convertLocalToWorldTransform(entity: Entity, localTransform: Transform) -> Transform? {
//    // Ensure the entity has a parent to convert to world coordinates
//    guard let parentEntity = entity.parent else {
//        print("Entity does not have a parent, cannot convert to world transform.")
//        return nil
//    }
//    
//    // Convert the local transform to the world transform
//    let worldTransform = entity.convert(transform: localTransform, from: parentEntity)
//    return worldTransform
//}

extension Angle: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let radians = try container.decode(Double.self)
        self = Angle(radians: radians)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.radians)
    }
}
