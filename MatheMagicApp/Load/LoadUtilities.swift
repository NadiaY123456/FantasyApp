////
////  LoadUtilities.swift
////  FantasyAppGithub
////
////  Created by Nadia Yilmaz on 12/26/24.
////
//
//import RealityKit
//import RealityKitContent
//import SwiftUI
//
//enum LoadUtilities {
//    @MainActor
//    static func loadFromRealityComposerPro(named entityName: String, fromSceneNamed sceneName: String) async -> Entity? {
//        var entity: Entity?
//        do {
//            let scene = try await Entity(named: sceneName, in: realityKitContentBundle)
//            entity = scene.findEntity(named: entityName)
//        } catch {
//            AppLogger.shared.error("Error loading \(entityName) from scene \(sceneName): \(error.localizedDescription)")
//        }
//        return entity
//    }
//
//    @MainActor
//    static func getEntityWithName(name: String, scene: Entity) -> some Entity {
//        if let localEntity = scene.findEntity(named: name) {
////            localEntity.generateCollisionShapes(recursive: false)
////            localEntity.components.set(InputTargetComponent())
//            // localEntity.components.set(HoverEffectComponent())
//            return localEntity
//        } else {
//            fatalError("Cannot find entity: \(name)")
//        }
//    }
//}
//
//func preLoadAssetsDict() async {
//    // Pre-load assets
//    for key in entityModelDictionary.keys {
//        print("Pre-loading assets for entityTemplate \(key)")
//        // Temporarily remove the value, mutate it, and reinsert it
//        if var entitySet = entityModelDictionary[key] {
//            await entitySet.loadEntity() // load entity
//
//            // Update the dictionary with the modified entity
//            entityModelDictionary[key] = entitySet
//        }
//    }
//}
