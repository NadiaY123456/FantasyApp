import RealityKit
import simd

// MARK: - Example 1: Basic Transform Inertialization

/// Demonstrates basic transform inertialization with different methods
func transformInertializationExample() {
    print("\n=== Transform Inertialization Example ===")
    
    // Setup initial transforms
    let oldPrevTransform = Transform(
        translation: SIMD3<Float>(0, 0, 0),
        rotation: simd_quatf(angle: 0.0, axis: SIMD3<Float>(0, 1, 0)),
        scale: SIMD3<Float>(1, 1, 1)
    )
    
    let prevTransform = Transform(
        translation: SIMD3<Float>(0.1, 0, 0),
        rotation: simd_quatf(angle: 0.1, axis: SIMD3<Float>(0, 1, 0)),
        scale: SIMD3<Float>(1, 1, 1)
    )
    
    let targetTransform = Transform(
        translation: SIMD3<Float>(1, 0, 0),
        rotation: simd_quatf(angle: 0.5, axis: SIMD3<Float>(0, 1, 0)),
        scale: SIMD3<Float>(1, 1, 1)
    )
    
    // Initialize inertialization data
    let deltaTime: Float = 1.0/60.0
    
    // Example 1: Polynomial magnitude approach 
    var polyConfig = InertializationConfig.smooth
    polyConfig.method = .magnitude
    polyConfig.positionMethod = .polynomial
    
    var polyData = initializeTransformInertialData(
        targetTransform: targetTransform,
        prevTransform: prevTransform,
        oldPrevTransform: oldPrevTransform,
        deltaTime: deltaTime,
        config: polyConfig
    )
    
    // Example 2: Spring-damper approach
    var springConfig = InertializationConfig.smooth
    springConfig.method = .magnitude
    springConfig.positionMethod = .springDamper
    
    var springData = initializeTransformInertialData(
        targetTransform: targetTransform,
        prevTransform: prevTransform,
        oldPrevTransform: oldPrevTransform,
        deltaTime: deltaTime,
        config: springConfig
    )
    
    // Apply inertialization over multiple frames
    print("\nComparing Polynomial vs Spring-Damper methods:")
    for i in 0..<5 {
        // Apply polynomial method
        let polyTransform = applyTransformInertial(
            data: &polyData,
            targetTransform: targetTransform,
            deltaTime: deltaTime
        )
        
        // Apply spring-damper method
        let springTransform = applyTransformInertial(
            data: &springData,
            targetTransform: targetTransform,
            deltaTime: deltaTime
        )
        
        print("Frame \(i):")
        print("  - Polynomial: \(polyTransform.translation)")
        print("  - Spring-Damper: \(springTransform.translation)")
    }
}

// MARK: - Example 2: Motion Matching with Inertialization

/// Demonstrates combining motion matching with inertialization
func motionMatchingExample() {
    print("\n=== Motion Matching Example ===")
    
    // Create a manager
    let manager = EnhancedMotionMatchingManager()
    
    // Configure system
    manager.configure(
        trajectoryWeight: 0.8,  // 80% weight on trajectory, 20% on pose
        use3DMode: true         // Use full 3D motion
    )
    
    // Simulate character motion
    let characterPosition = SIMD3<Float>(0, 0, 0)
    let characterVelocity = SIMD3<Float>(1, 0, 0)
    let targetPosition = SIMD3<Float>(10, 0, 0)
    
    let footLeftPosition = SIMD3<Float>(-0.1, 0, 0.1)
    let footRightPosition = SIMD3<Float>(0.1, 0, -0.1)
    let footVelocity = SIMD3<Float>(1, 0, 0)
    let hipVelocity = SIMD3<Float>(1, 0, 0)
    
    // Create a query feature
    let queryFeature = manager.createQueryFeature(
        currentPosition: characterPosition,
        currentVelocity: characterVelocity,
        targetPosition: targetPosition,
        footLeftPosition: footLeftPosition,
        footRightPosition: footRightPosition,
        footLeftVelocity: footVelocity,
        footRightVelocity: footVelocity,
        hipVelocity: hipVelocity
    )
    
    // Predict character trajectory using spring-damper system
    let predictedPath = manager.predictTrajectory(
        currentPosition: characterPosition,
        currentVelocity: characterVelocity,
        targetPosition: targetPosition,
        timePoints: [0.25, 0.5, 0.75, 1.0]
    )
    
    print("Predicted character path:")
    for (index, position) in predictedPath.enumerated() {
        print("  Time \(index): \(position)")
    }
    
    // Create a transform based on the feature
    let targetTransform = Transform(
        translation: queryFeature.trajectoryPositions.first ?? characterPosition,
        rotation: simd_quatf(angle: atan2(characterVelocity.z, characterVelocity.x),
                          axis: SIMD3<Float>(0, 1, 0)),
        scale: SIMD3<Float>(1, 1, 1)
    )
    
    // Initialize inertialization for the character
    let characterId = "player"
    let currentTransform = Transform(
        translation: characterPosition,
        rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0)),
        scale: SIMD3<Float>(1, 1, 1)
    )
    
    manager.initializeOrUpdateInertialization(
        for: characterId,
        targetTransform: targetTransform,
        currentTransform: currentTransform,
        previousTransform: currentTransform, // Same as current for initial setup
        deltaTime: 1.0/60.0,
        config: .smooth
    )
    
    // Apply inertialization for a few frames
    print("\nCharacter motion with inertialization:")
    for i in 0..<5 {
        let newTransform = manager.applyInertialization(
            for: characterId,
            targetTransform: targetTransform,
            deltaTime: 1.0/60.0
        )
        
        print("  Frame \(i): \(newTransform.translation)")
    }
}

// MARK: - Example 3: Skeleton Animation

/// Demonstrates bone-level inertialization for skeleton animation
func skeletonAnimationExample() {
    print("\n=== Skeleton Animation Example ===")
    
    // Create a manager
    let manager = EnhancedMotionMatchingManager()
    
    // Create a skeleton identifier
    let skeletonId = "humanoid"
    
    // Configure skeleton
    var config = InertializationConfig.default
    config.positionMethod = .springDamper
    config.stiffness = 20.0      // More responsive
    config.damping = 1.0         // Less damping for quicker movement
    config.blendTime = 0.2       // Fast transitions
    
    // Define bone transforms
    let bones: [String: Transform] = [
        "head": Transform(
            translation: SIMD3<Float>(0, 1.7, 0),
            rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(1, 0, 0)),
            scale: SIMD3<Float>(1, 1, 1)
        ),
        "spine": Transform(
            translation: SIMD3<Float>(0, 1.2, 0),
            rotation: simd_quatf(angle: 0.1, axis: SIMD3<Float>(0, 1, 0)),
            scale: SIMD3<Float>(1, 1, 1)
        ),
        "leftArm": Transform(
            translation: SIMD3<Float>(-0.4, 1.3, 0),
            rotation: simd_quatf(angle: -0.3, axis: SIMD3<Float>(0, 0, 1)),
            scale: SIMD3<Float>(1, 1, 1)
        ),
        "rightArm": Transform(
            translation: SIMD3<Float>(0.4, 1.3, 0),
            rotation: simd_quatf(angle: 0.3, axis: SIMD3<Float>(0, 0, 1)),
            scale: SIMD3<Float>(1, 1, 1)
        )
    ]
    
    // Initialize skeleton bones
    manager.initializeBonesForSkeleton(
        skeletonId: skeletonId,
        bones: bones,
        deltaTime: 1.0/60.0,
        config: config
    )
    
    // Create target poses (like a "waving" animation)
    let waveBones: [String: Transform] = [
        "head": Transform(
            translation: SIMD3<Float>(0, 1.7, 0),
            rotation: simd_quatf(angle: 0.1, axis: SIMD3<Float>(1, 0, 0)),
            scale: SIMD3<Float>(1, 1, 1)
        ),
        "spine": Transform(
            translation: SIMD3<Float>(0, 1.2, 0),
            rotation: simd_quatf(angle: 0.1, axis: SIMD3<Float>(0, 1, 0)),
            scale: SIMD3<Float>(1, 1, 1)
        ),
        "leftArm": Transform(
            translation: SIMD3<Float>(-0.4, 1.3, 0),
            rotation: simd_quatf(angle: -1.5, axis: SIMD3<Float>(0, 0, 1)),
            scale: SIMD3<Float>(1, 1, 1)
        ),
        "rightArm": Transform(
            translation: SIMD3<Float>(0.4, 1.3, 0.2),
            rotation: simd_quatf(angle: 0.8, axis: SIMD3<Float>(0, 0, 1)),
            scale: SIMD3<Float>(1, 1, 1)
        )
    ]
    
    // Animate the skeleton over several frames
    print("\nSkeleton animation with bone inertialization:")
    for i in 0..<5 {
        let animatedBones = manager.updateBonesForSkeleton(
            skeletonId: skeletonId,
            bones: waveBones,
            deltaTime: 1.0/60.0
        )
        
        print("Frame \(i):")
        for (boneName, transform) in animatedBones {
            print("  \(boneName): pos=\(transform.translation), rot=\(transform.rotation.angle)")
        }
    }
}

// MARK: - Example 4: Comparing Inertialization Methods

/// Demonstrates the difference between C3 and O3 approaches
func compareInertializationMethodsExample() {
    print("\n=== Method Comparison Example ===")
    
    // Setup
    let oldPrevTransform = Transform(
        translation: SIMD3<Float>(0, 0, 0),
        rotation: simd_quatf(angle: 0.0, axis: SIMD3<Float>(0, 1, 0)),
        scale: SIMD3<Float>(1, 1, 1)
    )
    
    let prevTransform = Transform(
        translation: SIMD3<Float>(0.1, 0, 0),
        rotation: simd_quatf(angle: 0.1, axis: SIMD3<Float>(0, 1, 0)),
        scale: SIMD3<Float>(1, 1, 1)
    )
    
    let targetTransform = Transform(
        translation: SIMD3<Float>(1, 0, 0),
        rotation: simd_quatf(angle: 0.5, axis: SIMD3<Float>(0, 1, 0)),
        scale: SIMD3<Float>(1, 1, 1)
    )
    
    let deltaTime: Float = 1.0/60.0
    
    // Create different configurations
    
    // 1. O3-style - polynomial with no overshoot prevention
    var o3Config = InertializationConfig.default
    o3Config.method = .magnitude
    o3Config.preventOvershoot = false  // O3 doesn't use overshoot prevention
    
    // 2. C3-style - polynomial with overshoot prevention
    var c3Config = InertializationConfig.default
    c3Config.method = .magnitude
    c3Config.preventOvershoot = true  // C3 uses overshoot prevention
    
    // 3. C3 extension - spring-damper approach
    var springConfig = InertializationConfig.default
    springConfig.method = .magnitude
    springConfig.positionMethod = .springDamper
    
    // 4. Direct method with O3 math approach
    var directConfig = InertializationConfig.default
    directConfig.method = .direct
    
    // Initialize all methods
    var o3Data = initializeTransformInertialData(
        targetTransform: targetTransform,
        prevTransform: prevTransform,
        oldPrevTransform: oldPrevTransform,
        deltaTime: deltaTime,
        config: o3Config
    )
    
    var c3Data = initializeTransformInertialData(
        targetTransform: targetTransform,
        prevTransform: prevTransform,
        oldPrevTransform: oldPrevTransform,
        deltaTime: deltaTime,
        config: c3Config
    )
    
    var springData = initializeTransformInertialData(
        targetTransform: targetTransform,
        prevTransform: prevTransform,
        oldPrevTransform: oldPrevTransform,
        deltaTime: deltaTime,
        config: springConfig
    )
    
    var directData = initializeTransformInertialData(
        targetTransform: targetTransform,
        prevTransform: prevTransform,
        oldPrevTransform: oldPrevTransform,
        deltaTime: deltaTime,
        config: directConfig
    )
    
    // Apply inertialization using all methods
    print("\nComparing inertialization methods:")
    for i in 0..<5 {
        let o3Transform = applyTransformInertial(
            data: &o3Data,
            targetTransform: targetTransform,
            deltaTime: deltaTime
        )
        
        let c3Transform = applyTransformInertial(
            data: &c3Data,
            targetTransform: targetTransform,
            deltaTime: deltaTime
        )
        
        let springTransform = applyTransformInertial(
            data: &springData,
            targetTransform: targetTransform,
            deltaTime: deltaTime
        )
        
        let directTransform = applyTransformInertial(
            data: &directData,
            targetTransform: targetTransform,
            deltaTime: deltaTime
        )
        
        print("Frame \(i):")
        print("  - O3 style (no overshoot prevention): \(o3Transform.translation)")
        print("  - C3 style (with overshoot prevention): \(c3Transform.translation)")
        print("  - Spring-damper method: \(springTransform.translation)")
        print("  - Direct method: \(directTransform.translation)")
    }
}

// MARK: - Example 5: Character Controller Demo

/// Demonstrates a practical character controller using the system
func characterControllerExample() {
    print("\n=== Character Controller Example ===")
    
    class CharacterController {
        private let motionManager = EnhancedMotionMatchingManager()
        private var currentTransform: Transform = .identity
        private var previousTransform: Transform = .identity
        
        // Character state
        enum CharacterState {
            case idle
            case walking
            case running
            case jumping
        }
        
        var currentState: CharacterState = .idle
        
        init() {
            // Configure motion system
            motionManager.configure(
                trajectoryWeight: 0.7,  // Prioritize trajectory
                use3DMode: true         // Use 3D features
            )
        }
        
        // Process input and update state
        func processInput(direction: SIMD3<Float>, speed: Float, jump: Bool) {
            // Determine new state based on input
            if jump {
                currentState = .jumping
            } else if speed > 0.7 {
                currentState = .running
            } else if speed > 0.1 {
                currentState = .walking
            } else {
                currentState = .idle
            }
            
            print("Character state: \(currentState)")
            
            // Calculate target transform based on input
            let targetPosition = currentTransform.translation + direction * speed
            let targetRotation = direction.x != 0 || direction.z != 0
                ? simd_quatf(angle: atan2(direction.z, direction.x), axis: SIMD3<Float>(0, 1, 0))
                : currentTransform.rotation
            
            let targetTransform = Transform(
                translation: targetPosition,
                rotation: targetRotation,
                scale: currentTransform.scale
            )
            
            // Apply appropriate inertialization based on state
            applyStateBasedInertialization(targetTransform)
        }
        
        private func applyStateBasedInertialization(_ targetTransform: Transform) {
            var config = InertializationConfig.default
            
            // Configure inertialization based on state
            switch currentState {
            case .idle:
                config.blendTime = 0.5
                config.positionMethod = .polynomial
            case .walking:
                config.blendTime = 0.3
                config.positionMethod = .polynomial
            case .running:
                config.blendTime = 0.2
                config.positionMethod = .springDamper
                config.stiffness = 15.0
                config.damping = 1.5
            case .jumping:
                config.blendTime = 0.15
                config.positionMethod = .springDamper
                config.stiffness = 20.0
                config.damping = 1.0
                config.use3D = true
            }
            
            // Initialize inertialization
            motionManager.initializeOrUpdateInertialization(
                for: "character",
                targetTransform: targetTransform,
                currentTransform: currentTransform,
                previousTransform: previousTransform,
                deltaTime: 1.0/60.0,
                config: config
            )
        }
        
        // Update the character each frame
        func update(deltaTime: Float) {
            previousTransform = currentTransform
            
            // Apply the current inertialization
            let targetTransform = Transform(
                translation: currentTransform.translation + SIMD3<Float>(0.1, 0, 0),
                rotation: currentTransform.rotation,
                scale: currentTransform.scale
            )
            
            currentTransform = motionManager.applyInertialization(
                for: "character",
                targetTransform: targetTransform,
                deltaTime: deltaTime
            )
            
            print("Character position: \(currentTransform.translation)")
        }
    }
    
    // Create character controller
    let character = CharacterController()
    
    // Simulate a few frames of movement
    print("Character movement simulation:")
    
    // Frame 1: Walking forward
    character.processInput(
        direction: SIMD3<Float>(1, 0, 0),
        speed: 0.5,
        jump: false
    )
    character.update(deltaTime: 1.0/60.0)
    
    // Frame 2: Running forward
    character.processInput(
        direction: SIMD3<Float>(1, 0, 0),
        speed: 0.8,
        jump: false
    )
    character.update(deltaTime: 1.0/60.0)
    
    // Frame 3: Jumping
    character.processInput(
        direction: SIMD3<Float>(1, 0, 0),
        speed: 0.8,
        jump: true
    )
    character.update(deltaTime: 1.0/60.0)
    
    // Frame 4: Still jumping
    character.processInput(
        direction: SIMD3<Float>(1, 0, 0),
        speed: 0.8,
        jump: true
    )
    character.update(deltaTime: 1.0/60.0)
    
    // Frame 5: Back to walking
    character.processInput(
        direction: SIMD3<Float>(1, 0, 0),
        speed: 0.5,
        jump: false
    )
    character.update(deltaTime: 1.0/60.0)
}

// MARK: - Run All Examples

/// Run all examples to demonstrate the system
func runAllExamples() {
    print("ENHANCED INERTIALIZATION SYSTEM EXAMPLES")
    print("========================================")
    
    // Run all examples
    transformInertializationExample()
    motionMatchingExample()
    skeletonAnimationExample()
    compareInertializationMethodsExample()
    characterControllerExample()
    
    print("\nAll examples completed successfully.")
}

//// Call to run all examples
//runAllExamples()
