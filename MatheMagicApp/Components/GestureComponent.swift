//
////
////  TestComponent.swift
////  FantasyAppGithub
////
////  Created by Nadia Yilmaz on 12/28/24.
////
//import RealityKit
//import SwiftUI
//
//public class EntityGestureState {
//    
//    /// The entity currently being tapped if a gesture is in progress.
//    var targetedEntity: Entity?
//    
//    
//    /// Marks whether the app is currently handling a tap gesture.
//    var isTapped = false
//    
//    
//    // MARK: - Singleton Accessor
//    
//    /// Retrieves the shared instance.
//    static let shared = EntityGestureState()
//}
//
//// MARK: -
//
///// A component that handles gesture logic for an entity.
//public struct GestureComponent: Component, Codable {
//    
//    /// A Boolean value that indicates whether a gesture can drag the entity.
//    public var canTap: Bool = true
//
//    
//    public init() {}
//    
//    // MARK: - Drag Logic
//        
//    
//    /// Handle `.onEnded` actions for drag gestures.
//    mutating func onEnded(value: EntityTargetValue<TapGesture.Value>) {
//        let state = EntityGestureState.shared
//        state.isTapped = false
//        
//        print("Tap gesture ended")
//
//        state.targetedEntity = nil
//    }
//
//}
//
//
//
//class GestureSystem: RealityKit.System {
//    @MainActor private static let query = EntityQuery(where: .has(GestureComponent.self))
//
//    required init(scene: RealityKit.Scene) {}
//
//    static var dependencies: [SystemDependency] { [] }
//
//    func update(context: SceneUpdateContext) {
//        // get the entities that have animation and motion component
//        let characters = context.entities(matching: Self.query, updatingSystemWhen: .rendering) // Used context.entities(matching:updatingSystemWhen:) instead of performQuery for better performance. TODO: update like this everywhere: https://forums.developer.apple.com/forums/thread/749064
//
//        for character in characters {
//            guard
//                var gestureComponent = character.components[GestureComponent.self]
//            else { continue }
//
//        }
//    }
//    
//    
//}
