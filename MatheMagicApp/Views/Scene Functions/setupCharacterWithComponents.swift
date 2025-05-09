import CoreLib
import RealityKit
import AnimLib
//
//  setupCharacterWithComponents.swift
//  MatheMagic
//
//

@MainActor func setupCharacterWithComponents(entityDictionaryID: String) -> Entity {
    var entity = Entity()
    if let template = entityModelDictionaryCore[entityDictionaryID] {
        entity = template.entity

        // Event Component
        entity.components[EventComponent.self] = EventComponent(dataProvider: GameModelView.shared)

        // Data Center Component
        if let dataManager = template.dataManager {
            entity.components[DataCenterComponent.self] = DataCenterComponent(dataManager: dataManager)
        }

        // Brain Component
        entity.components[BrainComponent.self] = BrainComponent()

        // Travel Component
        entity.components[TravelComponent.self] = TravelComponent()

        // Animation Component
        entity.components.set(AnimationComponent())

    } else { AppLogger.shared.error("Error: did not find \(entityDictionaryID) key in entityTemplateDictionary") }
    return entity
}
