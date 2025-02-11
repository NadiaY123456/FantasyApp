
import RealityKit
import SwiftUI


struct EntitySet {
    var name = String()
    var entity = Entity()
    var loadSource: LoadSource = .realityComposerPro
    var realityComposerName = ""
    var realityComposerScene = ""
    var usdzName = ""
    
    // input to loadEntity()
        enum LoadSource {
            case usdz
            case realityComposerPro
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
            print("Loaded \(name) from Reality Composer Pro project.")
        } else if loadSource == .usdz {
            guard let asset = try? await Entity(named: usdzName) else {
                fatalError("Unable to load \(name) from usdz file.")
            }
            entity = asset
            print("Loaded \(name) from usdz file.")
        }
    }
}
