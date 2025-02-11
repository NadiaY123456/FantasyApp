//import RealityKit
//
//
//struct CameraComponent: Component {
//    /// The entity that the camera will follow.
//    var target: Entity
//    
//    /// The positional offset of the camera relative to the target.
//    /// Adjust these values to change the camera's position behind, above, or to the side of the target.
//    var offset: SIMD3<Float> = SIMD3<Float>(0, 5, -10)
//}
//
//
//
//class CameraSystem: System {
//    // Define a query to find all entities with a CameraComponent
//    static var query: EntityQuery {
//        EntityQuery(where: .has(CameraComponent.self))
//    }
//    
//    // Initialize the system with the scene
//    required init(scene: Scene) {}
//    
//    // Declare dependencies if any (none in this case)
//    static var dependencies: [SystemDependency] { [] }
//    
//    // The update method is called every frame
//    func update(context: SceneUpdateContext) {
//        // Retrieve all entities that have a CameraComponent
//        let cameraEntities = context.scene.performQuery(Self.query)
//        
//        for camera in cameraEntities {
//            // Safely unwrap the CameraComponent
//            guard var cameraComponent = camera.components[CameraComponent.self] else { continue }
//            
//            // Ensure the target entity is still valid
//            let target = cameraComponent.target
//            guard target.exists else { continue }
//            
//            // Get the target's current transform
//            let targetTransform = target.transformMatrix(relativeTo: nil)
//            
//            // Calculate the new camera position by applying the offset
//            let newPosition = simd_float3(targetTransform.columns.3) + cameraComponent.offset
//            
//            // Update the camera's transform to the new position
//            camera.transform.translation = newPosition
//            
//            // Make the camera look at the target
//            camera.look(at: simd_float3(targetTransform.columns.3), from: newPosition, relativeTo: nil)
//        }
//    }
//}
