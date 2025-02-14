//
//  SceneManager.swift
//  MatheMagic
//

import RealityKit
import SwiftUI

class SceneManager: ObservableObject {

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

}
