
// Create the dictionary
var entityModelDictionary: [String: EntitySet] = Dictionary(uniqueKeysWithValues: [
    ("raven", ravenModel),
    ("flash", flashModel),
    ("meadow", meadowModel),
    ("water", waterModel)
])


var ravenModel = EntitySet (
    name: "Raven",
    loadSource: .realityComposerPro,
    realityComposerName: "Raven",
    realityComposerScene: "RavenScene"
)

var flashModel = EntitySet (
    name: "Flash",
    loadSource: .realityComposerPro,
    realityComposerName: "Flash",
    realityComposerScene: "FlashScene"
)

var meadowModel = EntitySet (
    name: "Meadow",
    loadSource: .realityComposerPro,
    realityComposerName: "Meadow",
    realityComposerScene: "Garden"
)

var waterModel = EntitySet (
    name: "WaterPlane",
    loadSource: .realityComposerPro,
    realityComposerName: "WaterPlane",
    realityComposerScene: "Garden"
)
