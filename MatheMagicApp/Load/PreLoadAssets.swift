import CoreLib
import RealityKit

@MainActor func preLoadAssetsDict() async {
    // Update Core Entity Dictionary
    let entityModelDictionary = setupEntitySets()
    CoreLib.addEntityModelToDictionaryToCore(entityModelDictionaryToAdd: entityModelDictionary)
    // Pre-load assets
    let dictionary = CoreLib.entityModelDictionaryCore
    for key in dictionary.keys {
        AppLogger.shared.info("Pre-loading assets for entityTemplate \(key)")
        // Temporarily remove the value, mutate it, and reinsert it∫
        if var entitySet = dictionary[key] {
            await entitySet.loadEntity() // load entity
            entitySet.setModelEntity() // set model entity
            entitySet.positionEntity() // position entity

            if entitySet.isAnimated {
//                await entitySet.loadRootAnimationAssets() // load associated root animations

                let dataManager = DataManager() // Create a DataManager instance for this entity

                // Load data
                dataManager.loadData(from: entitySet.jsonPathsToAnimData, as: AnimDataPoint.self) // populate animData for the entity from the external json
                dataManager.loadData(from: entitySet.jsonPathsToTransformData, as: TransformDataPoint.self) // populate transformData for the entity from the external json, which is replacement for usdz animation data

                // Load JointsNameList (this sets hierarchyManager)
                dataManager.loadData(from: entitySet.jsonPathsToJointNamesList, as: JointsNameList.self) // populate jointNamesList for the entity that corresponds to Transforms above (which are unnamed to save on space

                // Now that hierarchyManager is set, initialize side-dependent data. // Now boneIndices and bonePaths are cached and ready.
                dataManager.initializeSideDependentData() // caching bone paths

                // Assign the DataManager to the entity's property
                entitySet.dataManager = dataManager

//                // Optional: print loaded data for debugging
//                dataManager.printLoadedData(maxEntries: 3)
            }
//            entitySet.colliderData = dataManager.loadData(from: entitySet.jsonPathsToColliderData, as: MapDataPoint.self) // populate colliderData for the entity from the external json
//            if let colliderDataSet = dataManager.mapDataSet {
//                dataManager.printOrderedSet(colliderDataSet)
//                AppLogger.shared.info("DebugIsland: printed loaded json for index \(key) ")
//            }
            // Update the dictionary with the modified entity
            CoreLib.entityModelDictionaryCore[key] = entitySet
        }
    }
}

// Pre-Load entity (possibly without animations)
extension EntitySet {
    mutating func loadEntity() async {
        if loadSource == .realityComposerPro {
            guard let asset = await LoadUtilities.loadFromRealityComposerPro(
                named: realityComposerName,
                fromSceneNamed: realityComposerScene
            ) else {
                fatalError("Unable to load \(name) from Reality Composer Pro project.")
            }
            entity = asset
            AppLogger.shared.info("Loaded \(name) from Reality Composer Pro project.")
        } else if loadSource == .usdz {
            guard let asset = try? await Entity(named: usdzName) else {
                fatalError("Unable to load \(name) from usdz file.")
            }
            entity = asset
            AppLogger.shared.info("Loaded \(name) from usdz file.")
        }
    }
}

extension EntitySet {
    mutating func setModelEntity() {
        if let modelEntity = getModelEntity(from: entity, withName: modelEntityName) {
            self.modelEntity = modelEntity
            AppLogger.shared.info("ModelEntity set for \(name) with name \(modelEntityName).")
        } else {
            // Look for descendants with modelEntity
            if let entityChildrenWithModelComponent = entity.descendentsWithModelComponent as? [ModelEntity] {
                // Print list of names from list of above entities
                let entityNames = entityChildrenWithModelComponent.map { $0.name }
                AppLogger.shared.info("Found entities with model components: \(entityNames)")

                // Grab the first one as model entity if list is not empty
                if let firstEntity = entityChildrenWithModelComponent.first {
                    self.modelEntity = firstEntity
                    AppLogger.shared.info("ModelEntity set for \(name) using first available entity \(entityNames[0]).")
                } else {
                    // Otherwise, log an error
                    AppLogger.shared.error("ErrOR: ModelEntity with name \(modelEntityName) or any other name not found for \(name).")
                }
            } else {
                // Log an error if casting fails
                AppLogger.shared.error("ErrOR: Unable to cast descendants to [ModelEntity].")
            }
        }
    }
}

// to pre-load root animations. Runs in gameModel init()
//extension EntitySet {
//    mutating func loadRootAnimationAssets() async { // TODO: append animations from all sources together
//        guard isAnimated else { return }
//
//        if realityComposerAnimationResourceName != "" {
//            if realityComposerName != realityComposerAnimationResourceName {
//                guard let animationAsset = await LoadUtilities.loadFromRealityComposerPro(
//                    named: realityComposerAnimationResourceName,
//                    fromSceneNamed: realityComposerScene
//                ) else {
//                    fatalError("Unable to load \(name) from Reality Composer Pro project.")
//                }
//                animationSet = await animationAsset.availableAnimations
//            } else {
//                animationSet = await self.entity.availableAnimations
//            }
//            AppLogger.shared.info("Loaded \(name) animations from Reality Composer Pro project.")
//        }
//    }
//}
