import RealityKit
import SwiftUI

/// A component to track tap state for an entity.
public struct TapComponent: Component, Codable {
    /// Indicates that this entity was tapped since last frame.
    public var didTap: Bool = false
    
    public init() {}
}

/// A system that processes `TapComponent`.
public class TapSystem: RealityKit.System {
    /// We look for any entities that have a `TapComponent`.
    private static let query = EntityQuery(where: .has(TapComponent.self))
    // var gameModelView: GameModelView?
    
    public required init(scene: RealityKit.Scene) {}
    
    /// No dependencies on other systems for now.
    public static var dependencies: [SystemDependency] { [] }
    
    public func update(context: SceneUpdateContext) {
        // 1) Find all entities that have a TapComponent.
        let entities = context.entities(matching: Self.query,
                                        updatingSystemWhen: .rendering)
        
        // 2) For each entity, we can do anything we want with `didTap`.
        //    For example, we could do some quick visual effect or sound.
        //    Here we simply print a message (just for debugging).
        for entity in entities {
            guard var tapComponent = entity.components[TapComponent.self] else {
                continue
            }
            
            //print("didTap: \(tapComponent.didTap)")
            
            if tapComponent.didTap {
                print("Entity tapped: \(entity.name)")
                
                Task { @MainActor in
                    GameModelView.shared.showQuestion = true
                }
                
                tapComponent.didTap = false
                entity.components.set(tapComponent)
                
                //print("Show question: \(GameModelView.shared.showQuestion)")
            }
        }
    }
}

/// Attaches a tap event to an entity that has a `TapComponent`.
public extension Gesture where Value == EntityTargetValue<TapGesture.Value> {
    /// Connects the tap input to the `TapComponent` so that
    /// the system or SwiftUI can react to the tap event.
    func useTapComponent() -> some Gesture {
        onEnded { value in
            // 1) Check if the entity has a TapComponent.
            guard var tapComponent = value.entity.components[TapComponent.self] else {
                return
            }
            // 2) Record that a tap just happened.
            tapComponent.didTap = true
            // 3) Write the component back to the entity.
            value.entity.components[TapComponent.self] = tapComponent
        }
    }
}

public extension RealityView {
    var tapGesture: some Gesture {
        TapGesture()
            .targetedToAnyEntity()
            .useTapComponent()
    }
    
    /// Installs the tap gesture.
    /// You can combine multiple gestures here if needed.
    func installTapGesture() -> some View {
        simultaneousGesture(tapGesture)
    }
}
