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
                

                // Load all data types from the single .lzfse file using jsonPaths
                let dataPath = entitySet.jsonPaths.first ?? ""
                if !dataPath.isEmpty {
                    
                    dataManager.loadAllData(from: dataPath)
                    
                    // send corrent joint path to data manager and reorder all transforms and jointNameList accordingle

                    let modelJointNames = entitySet.modelEntity.jointNames
                    dataManager.setModelJointNames(modelJointNames)
                    dataManager.reorderTransformsAndJointList(with: modelJointNames)


                    // Initialize side-dependent data after loading joints
                    dataManager.initializeSideDependentData()

                    // Assign the DataManager to the entity's property
                    entitySet.dataManager = dataManager

                    // Clear the cache since data loading for this entity is complete
                    dataManager.clearDecompressedDataCache()

                    // Optional: Print loaded data for debugging
                    // dataManager.printLoadedData(maxEntries: 3)
                } else {
                    AppLogger.shared.warning("No data path provided for animated entity \(key)")
                }
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
                    AppLogger.shared.error("Error: ModelEntity with name \(modelEntityName) or any other name not found for \(name).")
                }
            } else {
                // Log an error if casting fails
                AppLogger.shared.error("Error: Unable to cast descendants to [ModelEntity].")
            }
        }
    }
}

// to pre-load root animations. Runs in gameModel init()
// extension EntitySet {
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
// }
