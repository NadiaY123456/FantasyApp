import CoreLib
import SwiftUI
import Spatial

@MainActor func setupEntitySets()
    -> [String: EntitySet]
{
    
//    let ravenModel = EntitySet(
//        name: "Raven",
//        modelEntityName: "BoneRoot",
//        entityType: .character,
//        loadSource: .realityComposerPro,
//        realityComposerName: "Raven",
//        realityComposerScene: "RavenScene",
//        usdzName: "",
//        realityComposerAnimationResourceName: "raven",
//        jsonPathsToAnimData: ["/Users/nata/GitHub/NextTaleApp/NataRestart/DataToImport.bundle/raven/animMeta/"],
//        jsonPathsToTransformData: ["/Users/nata/GitHub/NextTaleApp/NataRestart/DataToImport.bundle/raven/transforms/"],
//        jsonPathsToJointNamesList: ["/Users/nata/GitHub/NextTaleApp/NataRestart/DataToImport.bundle/raven/raven_joints.json"],
//        isAnimated: true,
//        isMoving: true,
//        position: SIMD3(x: 0, y: 0, z: -2.5),
//        orientation: simd_quatf(
//            Rotation3D(angle: .degrees(0), axis: .x)
//                .rotated(by: Rotation3D(angle: .degrees(0), axis: .z))
//        ),
//        spawnScaleFactor: SIMD3<Float>(0.1, 0.1, 0.1)
//    )
    
    let flashModel = EntitySet(
        name: "flash",
        modelEntityName: "BoneRoot",
        entityType: .character,
        loadSource: .realityComposerPro,
        realityComposerName: "flash",
        realityComposerScene: "FlashScene",
        usdzName: "",
        realityComposerAnimationResourceName: "flash",
        jsonPaths: ["DataToImport.bundle/flash/flash.lzfse"], //["DataToImport.bundle/flash"]
        isAnimated: true,
        isMoving: true,
        position: SIMD3(x: 0, y: 0, z: 0),
        orientation: simd_quatf(
            Rotation3D(angle: .degrees(0), axis: .x)
                .rotated(by: Rotation3D(angle: .degrees(0), axis: .z))
        ),
        spawnScaleFactor: SIMD3<Float>(0.1, 0.1, 0.1)
    )
    
    let meadowModel = EntitySet(
        name: "Meadow",
        modelEntityName: "Meadow",
        entityType: .island,
        loadSource: .realityComposerPro,
        realityComposerName: "Meadow",
        realityComposerScene: "Garden",
        usdzName: "",
        realityComposerAnimationResourceName: "",
        jsonPaths: [""],
        isAnimated: false,
        isMoving: false,
        position: SIMD3(x: 0, y: -0.2, z: 0),
        orientation: simd_quatf(
            Rotation3D(angle: .degrees(0), axis: .y)
                .rotated(by: Rotation3D(angle: .degrees(0), axis: .z))
        ),
        spawnScaleFactor: SIMD3<Float>(1.0, 0.001, 1.0)
    )
    
    let waterModel = EntitySet(
        name: "WaterPlane",
        modelEntityName: "WaterPlane",
        entityType: .island,
        loadSource: .realityComposerPro,
        realityComposerName: "WaterPlane",
        realityComposerScene: "Garden",
        usdzName: "",
        realityComposerAnimationResourceName: "",
        jsonPaths: [""],
        isAnimated: false,
        isMoving: false,
        position: SIMD3(x: 0, y: -0.2, z: 0),
        orientation: simd_quatf(
            Rotation3D(angle: .degrees(0), axis: .y)
                .rotated(by: Rotation3D(angle: .degrees(0), axis: .z))
        ),
        spawnScaleFactor: SIMD3<Float>(1.0, 0.001, 1.0)
    )
    
    let planeModel = EntitySet(
        name: "plane",
        modelEntityName: "plane",
        entityType: .island,
        loadSource: .realityComposerPro,
        realityComposerName: "plane",
        realityComposerScene: "planeScene",
        usdzName: "",
        realityComposerAnimationResourceName: "",
        jsonPaths: [""],
        isAnimated: false,
        isMoving: false,
        position: SIMD3(x: 0, y: -0.1, z: 0),
        orientation: simd_quatf(
            Rotation3D(angle: .degrees(0), axis: .y)
                .rotated(by: Rotation3D(angle: .degrees(0), axis: .z))
        ),
        spawnScaleFactor: SIMD3<Float>(1.0, 0.001, 1.0)
    )
    
    // Create the dictionary
    let entityModelDictionary: [String: EntitySet] = Dictionary(uniqueKeysWithValues: [
        ("flash", flashModel),
//        ("raven", ravenModel),
        ("plane", planeModel),
        ("meadow", meadowModel),
        ("water", waterModel)
    ])
    
    return entityModelDictionary
}



//// Create the dictionary
//var entityModelDictionary: [String: EntitySet] = Dictionary(uniqueKeysWithValues: [
//    ("raven", ravenModel),
//    ("flash", flashModel),
//    ("meadow", meadowModel),
//    ("water", waterModel)
//])
//
//
//var ravenModel = EntitySet (
//    name: "Raven",
//    loadSource: .realityComposerPro,
//    realityComposerName: "Raven",
//    realityComposerScene: "RavenScene"
//)
//
//var flashModel = EntitySet (
//    name: "Flash",
//    loadSource: .realityComposerPro,
//    realityComposerName: "Flash",
//    realityComposerScene: "FlashScene"
//)
//
//var meadowModel = EntitySet (
//    name: "Meadow",
//    loadSource: .realityComposerPro,
//    realityComposerName: "Meadow",
//    realityComposerScene: "Garden"
//)
//
//var waterModel = EntitySet (
//    name: "WaterPlane",
//    loadSource: .realityComposerPro,
//    realityComposerName: "WaterPlane",
//    realityComposerScene: "Garden"
//)
