import RealityKit
import simd

/// Manager for enhanced motion matching with spring-damper, 3D support, and weighted loss
class EnhancedMotionMatchingManager {
    // MARK: - Properties
    
    // Spring damper system for trajectory prediction
    private var springDamper = SpringDamperSystem()
    
    // Loss function for motion matching
    private var lossFunction = WeightedLossFunction()
    
    // Separate databases for 2D and 3D motions
    private var database2D: [MotionFeature] = []
    private var database3D: [MotionFeature] = []
    
    // Current mode (2D or 3D)
    private var use3DMode: Bool = true
    
    // Inertialization data per entity
    private var inertializationData: [String: TransformInertialData] = [:]
    
    // Skeleton inertializers for bone-level control
    private var skeletonInertializers: [String: SkeletonInertializer] = [:]
    
    // MARK: - Initialization
    
    /// Initialize with motion databases
    init(database2D: [MotionFeature] = [], database3D: [MotionFeature] = []) {
        self.database2D = database2D
        self.database3D = database3D
    }
    
    // MARK: - Configuration
    
    /// Configure the motion matching parameters
    func configure(trajectoryWeight: Float? = nil, use3DMode: Bool? = nil, preventOvershoot: Bool? = nil) {
        if let weight = trajectoryWeight {
            lossFunction.trajectoryWeight = weight
            lossFunction.poseWeight = 1.0 - weight
        }
        
        if let mode = use3DMode {
            self.use3DMode = mode
        }
    }
    
    // MARK: - Motion Matching
    
    /// Find best matching motion from the database
    func findBestMatch(query: MotionFeature) -> (index: Int, feature: MotionFeature) {
        // Select appropriate database
        let database = use3DMode ? database3D : database2D
        
        if database.isEmpty {
            // Return default if database is empty
            return (0, MotionFeature())
        }
        
        // Find best match (lowest distance)
        var bestIndex = 0
        var bestDistance = Float.greatestFiniteMagnitude
        
        for (index, candidate) in database.enumerated() {
            let distance = lossFunction.calculateDistance(
                query: query,
                candidate: candidate,
                use3D: use3DMode
            )
            
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }
        
        return (bestIndex, database[bestIndex])
    }
    
    /// Generate future trajectory using spring-damper system
    func predictTrajectory(
        currentPosition: SIMD3<Float>,
        currentVelocity: SIMD3<Float>,
        targetPosition: SIMD3<Float>,
        timePoints: [Float] = [0.33, 0.67, 1.0]
    ) -> [SIMD3<Float>] {
        return springDamper.predictTrajectory(
            currentPosition: currentPosition,
            currentVelocity: currentVelocity,
            targetPosition: targetPosition,
            timePoints: timePoints
        )
    }
    
    /// Create query feature for motion matching
    func createQueryFeature(
        currentPosition: SIMD3<Float>,
        currentVelocity: SIMD3<Float>,
        targetPosition: SIMD3<Float>,
        footLeftPosition: SIMD3<Float>,
        footRightPosition: SIMD3<Float>,
        footLeftVelocity: SIMD3<Float>,
        footRightVelocity: SIMD3<Float>,
        hipVelocity: SIMD3<Float>
    ) -> MotionFeature {
        // Predict future trajectory using spring-damper
        let trajectoryPositions = predictTrajectory(
            currentPosition: currentPosition,
            currentVelocity: currentVelocity,
            targetPosition: targetPosition
        )
        
        // Calculate directions from positions
        var trajectoryDirections: [SIMD3<Float>] = []
        if trajectoryPositions.count >= 2 {
            for i in 0..<(trajectoryPositions.count - 1) {
                let dir = trajectoryPositions[i + 1] - trajectoryPositions[i]
                if simd_length(dir) > Epsilon.position {
                    trajectoryDirections.append(simd_normalize(dir))
                } else {
                    trajectoryDirections.append(SIMD3<Float>(1, 0, 0))
                }
            }
        }
        
        // Create the feature vector
        return MotionFeature(
            trajectoryPositions: trajectoryPositions,
            trajectoryDirections: trajectoryDirections,
            footLeftPosition: footLeftPosition,
            footRightPosition: footRightPosition,
            footLeftVelocity: footLeftVelocity,
            footRightVelocity: footRightVelocity,
            hipVelocity: hipVelocity
        )
    }
    
    // MARK: - Transform Inertialization
    
    /// Initializes or updates inertialization for a specific entity
    func initializeOrUpdateInertialization(
        for identifier: String,
        targetTransform: Transform,
        currentTransform: Transform,
        previousTransform: Transform,
        deltaTime: Float,
        config: InertializationConfig = .default,
        blendTime: Float? = nil
    ) {
        // Apply custom blend time if provided
        var modifiedConfig = config
        if let explicitBlend = blendTime {
            modifiedConfig.blendTime = explicitBlend
        }
        
        // Only initialize if no active inertialization exists
        if let existing = inertializationData[identifier], existing.isActive {
            // Continue with existing inertialization
        } else {
            inertializationData[identifier] = initializeTransformInertialData(
                targetTransform: targetTransform,
                prevTransform: currentTransform,
                oldPrevTransform: previousTransform,
                deltaTime: deltaTime,
                config: modifiedConfig
            )
        }
    }
    
    /// Applies inertialization to update the transform of an entity
    func applyInertialization(
        for identifier: String,
        targetTransform: Transform,
        deltaTime: Float
    ) -> Transform {
        guard var data = inertializationData[identifier], data.isActive else {
            return targetTransform
        }
        
        let result = applyTransformInertial(
            data: &data,
            targetTransform: targetTransform,
            deltaTime: deltaTime
        )
        
        // Update data and clean up if necessary
        inertializationData[identifier] = data
        if !data.isActive {
            inertializationData.removeValue(forKey: identifier)
        }
        
        return result
    }
    
    // MARK: - Skeleton Inertialization
    
    /// Creates a new skeleton inertializer or returns an existing one
    func getSkeletonInertializer(
        for identifier: String,
        config: InertializationConfig = .default
    ) -> SkeletonInertializer {
        if let existing = skeletonInertializers[identifier] {
            return existing
        }
        
        let newSkeleton = SkeletonInertializer(config: config)
        skeletonInertializers[identifier] = newSkeleton
        return newSkeleton
    }
    
    /// Initialize bones for a specific skeleton
    func initializeBonesForSkeleton(
        skeletonId: String,
        bones: [String: Transform],
        deltaTime: Float,
        config: InertializationConfig = .default
    ) {
        let skeleton = getSkeletonInertializer(for: skeletonId, config: config)
        skeleton.initializeBones(targetTransforms: bones, deltaTime: deltaTime)
    }
    
    /// Update bones for a specific skeleton
    func updateBonesForSkeleton(
        skeletonId: String,
        bones: [String: Transform],
        deltaTime: Float
    ) -> [String: Transform] {
        guard let skeleton = skeletonInertializers[skeletonId] else {
            return bones
        }
        
        return skeleton.update(targetTransforms: bones, deltaTime: deltaTime)
    }
    
    // MARK: - Utility Methods
    
    /// Stops inertialization for a specific entity
    func stopInertialization(for identifier: String) {
        inertializationData.removeValue(forKey: identifier)
    }
    
    /// Checks if an entity has active inertialization
    func hasActiveInertialization(for identifier: String) -> Bool {
        return inertializationData[identifier]?.isActive ?? false
    }
    
    /// Stops all active inertializations
    func stopAllInertializations() {
        inertializationData.removeAll()
    }
    
    /// Clears all caches to free memory
    func clearCaches() {
        springDamper.clearCache()
        lossFunction.clearCache()
        PolynomialCache.shared.clear()
        QuaternionCache.shared.clear()
    }
}

// MARK: - Spring Damper System

/// Spring damper system for trajectory prediction
/// Implements equations for more natural motion transitions
class SpringDamperSystem {
    /// Parameter controlling decay rate
    var decayRate: Float = 4.0
    
    /// Cache for spring damper computations
    private var cache: [String: SIMD3<Float>] = [:]
    
    /// Predict future position using spring-damper model
    func predictPosition(
        currentPosition: SIMD3<Float>, 
        currentVelocity: SIMD3<Float>,
        targetPosition: SIMD3<Float>, 
        deltaTime: Float
    ) -> SIMD3<Float> {
        // Generate cache key
        let cacheKey = "\(currentPosition),\(currentVelocity),\(targetPosition),\(deltaTime)"
        
        // Check cache first
        if let cachedResult = cache[cacheKey] {
            return cachedResult
        }
        
        // Calculate coefficients for spring-damper system
        // x0 is the offset from target to current
        let x0 = currentPosition - targetPosition
        let v0 = currentVelocity
        let y = decayRate / 2.0
        
        // j0, j1, and c are coefficients from equation (10)
        let c = targetPosition
        let j0 = x0
        let j1 = v0 + j0 * y
        
        // Calculate the movement at time deltaTime using equation (11)
        // x(t) = (j0 + j1*t)e^(-yt) + c
        let result = j0 * exp(-y * deltaTime) + 
                    j1 * deltaTime * exp(-y * deltaTime) + c
        
        // Cache the result
        if cache.count > 100 { cache.removeAll(keepingCapacity: true) } // Prevent unbounded growth
        cache[cacheKey] = result
        
        return result
    }
    
    /// Predict multiple future positions using spring-damper model
    func predictTrajectory(
        currentPosition: SIMD3<Float>,
        currentVelocity: SIMD3<Float>,
        targetPosition: SIMD3<Float>,
        timePoints: [Float]
    ) -> [SIMD3<Float>] {
        return timePoints.map { t in
            predictPosition(
                currentPosition: currentPosition,
                currentVelocity: currentVelocity,
                targetPosition: targetPosition,
                deltaTime: t
            )
        }
    }
    
    /// Clear the cache
    func clearCache() {
        cache.removeAll(keepingCapacity: true)
    }
}

// MARK: - Weighted Loss Function

/// Weighted loss function for motion matching
/// Prioritizes trajectory features over pose features for better motion alignment
struct WeightedLossFunction {
    /// Weight for trajectory features (higher means more importance on following trajectory)
    var trajectoryWeight: Float = 0.8
    
    /// Weight for pose features
    var poseWeight: Float = 0.2
    
    /// Cache for distance calculations to avoid recalculating
    private var distanceCache: [String: Float] = [:]
    
    /// Calculate weighted distance between query and candidate features
    mutating func calculateDistance(
        query: MotionFeature, 
        candidate: MotionFeature, 
        use3D: Bool = true
    ) -> Float {
        // Generate cache key
        let querySig = query.trajectoryPositions.hashValue ^ query.footLeftPosition.hashValue
        let candidateSig = candidate.trajectoryPositions.hashValue ^ candidate.footLeftPosition.hashValue
        let cacheKey = "\(querySig),\(candidateSig),\(use3D)"
        
        // Check cache first
        if let cachedDistance = distanceCache[cacheKey] {
            return cachedDistance
        }
        
        // Extract feature vectors
        let queryTrajectory = query.getTrajectoryFeatures(use3D: use3D)
        let candidateTrajectory = candidate.getTrajectoryFeatures(use3D: use3D)
        let queryPose = query.getPoseFeatures(use3D: use3D)
        let candidatePose = candidate.getPoseFeatures(use3D: use3D)
        
        // Calculate squared differences for trajectory features
        var trajectoryDistance: Float = 0
        for i in 0..<min(queryTrajectory.count, candidateTrajectory.count) {
            let diff = queryTrajectory[i] - candidateTrajectory[i]
            trajectoryDistance += diff * diff
        }
        
        // Calculate squared differences for pose features
        var poseDistance: Float = 0
        for i in 0..<min(queryPose.count, candidatePose.count) {
            let diff = queryPose[i] - candidatePose[i]
            poseDistance += diff * diff
        }
        
        // Apply weights
        let distance = trajectoryWeight * trajectoryDistance + poseWeight * poseDistance
        
        // Cache the result
        if distanceCache.count > 1000 { distanceCache.removeAll(keepingCapacity: true) }
        distanceCache[cacheKey] = distance
        
        return distance
    }
    
    /// Clear the cache
    mutating func clearCache() {
        distanceCache.removeAll(keepingCapacity: true)
    }
}

// MARK: - Motion Feature Vector

/// Feature vector for motion matching with full 3D support
struct MotionFeature {
    // Future trajectory points (positions in 3D)
    var trajectoryPositions: [SIMD3<Float>] = []
    
    // Future trajectory directions (normalized directions in 3D)
    var trajectoryDirections: [SIMD3<Float>] = []
    
    // Current pose features (joint positions, velocities, etc.)
    var footLeftPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var footRightPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var footLeftVelocity: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var footRightVelocity: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var hipVelocity: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    
    // Initialize from components
    init(trajectoryPositions: [SIMD3<Float>] = [],
         trajectoryDirections: [SIMD3<Float>] = [],
         footLeftPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
         footRightPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
         footLeftVelocity: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
         footRightVelocity: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
         hipVelocity: SIMD3<Float> = SIMD3<Float>(0, 0, 0)) {
        self.trajectoryPositions = trajectoryPositions
        self.trajectoryDirections = trajectoryDirections
        self.footLeftPosition = footLeftPosition
        self.footRightPosition = footRightPosition
        self.footLeftVelocity = footLeftVelocity
        self.footRightVelocity = footRightVelocity
        self.hipVelocity = hipVelocity
    }
    
    /// Extract trajectory features for comparison (can be 2D or 3D)
    func getTrajectoryFeatures(use3D: Bool = true) -> [Float] {
        var features: [Float] = []
        
        for pos in trajectoryPositions {
            // For 2D, only use x and z components
            // For 3D, include y component as well
            if use3D {
                features.append(pos.x)
                features.append(pos.y)
                features.append(pos.z)
            } else {
                features.append(pos.x)
                features.append(pos.z)
            }
        }
        
        for dir in trajectoryDirections {
            if use3D {
                features.append(dir.x)
                features.append(dir.y)
                features.append(dir.z)
            } else {
                features.append(dir.x)
                features.append(dir.z)
            }
        }
        
        return features
    }
    
    /// Extract pose features for comparison
    func getPoseFeatures(use3D: Bool = true) -> [Float] {
        var features: [Float] = []
        
        if use3D {
            // Full 3D pose features
            features.append(contentsOf: [
                footLeftPosition.x, footLeftPosition.y, footLeftPosition.z,
                footRightPosition.x, footRightPosition.y, footRightPosition.z,
                footLeftVelocity.x, footLeftVelocity.y, footLeftVelocity.z,
                footRightVelocity.x, footRightVelocity.y, footRightVelocity.z,
                hipVelocity.x, hipVelocity.y, hipVelocity.z
            ])
        } else {
            // 2D pose features (dropping y component)
            features.append(contentsOf: [
                footLeftPosition.x, footLeftPosition.z,
                footRightPosition.x, footRightPosition.z,
                footLeftVelocity.x, footLeftVelocity.z,
                footRightVelocity.x, footRightVelocity.z,
                hipVelocity.x, hipVelocity.z
            ])
        }
        
        return features
    }
}

// MARK: - Bone and Skeleton Inertializers

/// Bone inertializer for more granular control over skeletal animation
class BoneInertializer {
    private let config: InertializationConfig
    private var transformData: TransformInertialData?
    private var prevTransform: Transform
    private var oldPrevTransform: Transform
    
    init(config: InertializationConfig, initialTransform: Transform) {
        self.config = config
        self.prevTransform = initialTransform
        self.oldPrevTransform = initialTransform
    }
    
    var isActive: Bool {
        return transformData?.isActive ?? false
    }
    
    func initialize(targetTransform: Transform, deltaTime: Float) {
        transformData = initializeTransformInertialData(
            targetTransform: targetTransform,
            prevTransform: prevTransform,
            oldPrevTransform: oldPrevTransform,
            deltaTime: deltaTime,
            config: config
        )
        oldPrevTransform = prevTransform
    }
    
    func update(targetTransform: Transform, deltaTime: Float) -> Transform {
        guard var data = transformData, data.isActive else {
            prevTransform = targetTransform
            return targetTransform
        }
        
        let result = applyTransformInertial(
            data: &data,
            targetTransform: targetTransform,
            deltaTime: deltaTime
        )
        
        transformData = data
        oldPrevTransform = prevTransform
        prevTransform = result
        
        return result
    }
}

/// Controls multiple bones in a skeleton for cohesive animation
class SkeletonInertializer {
    private var boneInertializers: [String: BoneInertializer] = [:]
    private let config: InertializationConfig
    
    init(config: InertializationConfig) {
        self.config = config
    }
    
    func addBone(id: String, initialTransform: Transform) {
        boneInertializers[id] = BoneInertializer(
            config: config,
            initialTransform: initialTransform
        )
    }
    
    func initializeBones(targetTransforms: [String: Transform], deltaTime: Float) {
        for (boneId, targetTransform) in targetTransforms {
            if let inertializer = boneInertializers[boneId] {
                inertializer.initialize(targetTransform: targetTransform, deltaTime: deltaTime)
            } else {
                // Create a new inertializer if it doesn't exist
                let newInertializer = BoneInertializer(config: config, initialTransform: targetTransform)
                boneInertializers[boneId] = newInertializer
                newInertializer.initialize(targetTransform: targetTransform, deltaTime: deltaTime)
            }
        }
    }
    
    func update(targetTransforms: [String: Transform], deltaTime: Float) -> [String: Transform] {
        var results: [String: Transform] = [:]
        
        for (boneId, targetTransform) in targetTransforms {
            if let inertializer = boneInertializers[boneId] {
                results[boneId] = inertializer.update(
                    targetTransform: targetTransform,
                    deltaTime: deltaTime
                )
            } else {
                results[boneId] = targetTransform
            }
        }
        
        return results
    }
    
    func hasBone(id: String) -> Bool {
        return boneInertializers[id] != nil
    }
    
    func boneIsActive(id: String) -> Bool {
        return boneInertializers[id]?.isActive ?? false
    }
    
    var activeBonesCount: Int {
        return boneInertializers.values.filter { $0.isActive }.count
    }
}

// MARK: - Usage Example

/// Example demonstrating how to use the enhanced system
func basicExample() {
    print("=== Enhanced Inertialization Example ===")
    
    // Create manager
    let manager = EnhancedMotionMatchingManager()
    
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
    
    // Initialize for entity 1 with polynomial approach
    var config = InertializationConfig.fast
    config.method = .magnitude
    config.positionMethod = .polynomial
    
    let entity1 = "character_poly"
    manager.initializeOrUpdateInertialization(
        for: entity1,
        targetTransform: targetTransform,
        currentTransform: prevTransform,
        previousTransform: oldPrevTransform,
        deltaTime: 1.0/60.0,
        config: config,
        blendTime: 0.25
    )
    
    // Apply inertialization
    let resultTransform = manager.applyInertialization(
        for: entity1,
        targetTransform: targetTransform,
        deltaTime: 1.0/60.0
    )
    
    print("Character at position: \(resultTransform.translation)")
}

/* G3 version:
 import RealityKit
 import simd

 // MARK: - Spring-Damper System for Trajectory Prediction

 struct SpringDamperSystem {
     var decayRate: Float = 4.0
     private var cache: [String: SIMD3<Float>] = [:]

     mutating func predictPosition(currentPosition: SIMD3<Float>, currentVelocity: SIMD3<Float>, targetPosition: SIMD3<Float>, deltaTime: Float) -> SIMD3<Float> {
         let key = "\(currentPosition),\(currentVelocity),\(targetPosition),\(deltaTime)"
         if let cached = cache[key] { return cached }
         let x0 = currentPosition - targetPosition
         let v0 = currentVelocity
         let y = decayRate / 2
         let result = (x0 + (v0 + x0 * y) * deltaTime) * exp(-y * deltaTime) + targetPosition
         if cache.count > 100 { cache.removeAll(keepingCapacity: true) }
         cache[key] = result
         return result
     }

     mutating func predictTrajectory(currentPosition: SIMD3<Float>, currentVelocity: SIMD3<Float>, targetPosition: SIMD3<Float>, timePoints: [Float]) -> [SIMD3<Float>] {
         timePoints.map { predictPosition(currentPosition: currentPosition, currentVelocity: currentVelocity, targetPosition: targetPosition, deltaTime: $0) }
     }

     mutating func clearCache() {
         cache.removeAll(keepingCapacity: true)
     }
 }

 // MARK: - Motion Feature

 struct MotionFeature {
     var trajectoryPositions: [SIMD3<Float>] = []
     var trajectoryDirections: [SIMD3<Float>] = []
     var footLeftPosition: SIMD3<Float> = .zero
     var footRightPosition: SIMD3<Float> = .zero
     var footLeftVelocity: SIMD3<Float> = .zero
     var footRightVelocity: SIMD3<Float> = .zero
     var hipVelocity: SIMD3<Float> = .zero

     func getTrajectoryFeatures(use3D: Bool) -> [Float] {
         var features: [Float] = []
         for pos in trajectoryPositions {
             features.append(pos.x)
             if use3D { features.append(pos.y) }
             features.append(pos.z)
         }
         for dir in trajectoryDirections {
             features.append(dir.x)
             if use3D { features.append(dir.y) }
             features.append(dir.z)
         }
         return features
     }

     func getPoseFeatures(use3D: Bool) -> [Float] {
         use3D ? [
             footLeftPosition.x, footLeftPosition.y, footLeftPosition.z,
             footRightPosition.x, footRightPosition.y, footRightPosition.z,
             footLeftVelocity.x, footLeftVelocity.y, footLeftVelocity.z,
             footRightVelocity.x, footRightVelocity.y, footRightVelocity.z,
             hipVelocity.x, hipVelocity.y, hipVelocity.z
         ] : [
             footLeftPosition.x, footLeftPosition.z,
             footRightPosition.x, footRightPosition.z,
             footLeftVelocity.x, footLeftVelocity.z,
             footRightVelocity.x, footRightVelocity.z,
             hipVelocity.x, hipVelocity.z
         ]
     }
 }

 // MARK: - Weighted Loss Function

 struct WeightedLossFunction {
     var trajectoryWeight: Float = 0.8
     var poseWeight: Float = 0.2
     private var distanceCache: [String: Float] = [:]

     mutating func calculateDistance(query: MotionFeature, candidate: MotionFeature, use3D: Bool) -> Float {
         let key = "\(query.trajectoryPositions.hashValue),\(candidate.trajectoryPositions.hashValue),\(use3D)"
         if let cached = distanceCache[key] { return cached }
         let queryTraj = query.getTrajectoryFeatures(use3D: use3D)
         let candTraj = candidate.getTrajectoryFeatures(use3D: use3D)
         let queryPose = query.getPoseFeatures(use3D: use3D)
         let candPose = candidate.getPoseFeatures(use3D: use3D)
         let trajDist = zip(queryTraj, candTraj).reduce(0) { $0 + pow($1.0 - $1.1, 2) }
         let poseDist = zip(queryPose, candPose).reduce(0) { $0 + pow($1.0 - $1.1, 2) }
         let distance = trajectoryWeight * trajDist + poseWeight * poseDist
         if distanceCache.count > 1000 { distanceCache.removeAll(keepingCapacity: true) }
         distanceCache[key] = distance
         return distance
     }

     mutating func clearCache() {
         distanceCache.removeAll(keepingCapacity: true)
     }
 }

 // MARK: - Motion Matching Manager

 class EnhancedMotionMatchingManager {
     private var springDamper = SpringDamperSystem()
     private var lossFunction = WeightedLossFunction()
     private var database2D: [MotionFeature] = []
     private var database3D: [MotionFeature] = []
     private var use3DMode: Bool = false
     private var inertializationData: [String: TransformInertialData] = [:]
     private var skeletonInertializers: [String: SkeletonInertializer] = [:]

     init(database2D: [MotionFeature] = [], database3D: [MotionFeature] = []) {
         self.database2D = database2D
         self.database3D = database3D
     }

     func configure(trajectoryWeight: Float? = nil, use3DMode: Bool? = nil) {
         if let weight = trajectoryWeight {
             lossFunction.trajectoryWeight = weight
             lossFunction.poseWeight = 1 - weight
         }
         if let mode = use3DMode { self.use3DMode = mode }
     }

     func findBestMatch(query: MotionFeature) -> (index: Int, feature: MotionFeature) {
         let database = use3DMode ? database3D : database2D
         guard !database.isEmpty else { return (0, MotionFeature()) }
         var bestIndex = 0
         var bestDistance = Float.greatestFiniteMagnitude
         for (i, candidate) in database.enumerated() {
             let distance = lossFunction.calculateDistance(query: query, candidate: candidate, use3D: use3DMode)
             if distance < bestDistance {
                 bestDistance = distance
                 bestIndex = i
             }
         }
         return (bestIndex, database[bestIndex])
     }

     func predictTrajectory(currentPosition: SIMD3<Float>, currentVelocity: SIMD3<Float>, targetPosition: SIMD3<Float>, timePoints: [Float] = [0.33, 0.67, 1.0]) -> [SIMD3<Float>] {
         springDamper.predictTrajectory(currentPosition: currentPosition, currentVelocity: currentVelocity, targetPosition: targetPosition, timePoints: timePoints)
     }

     func createQueryFeature(currentPosition: SIMD3<Float>, currentVelocity: SIMD3<Float>, targetPosition: SIMD3<Float>, footLeftPosition: SIMD3<Float>, footRightPosition: SIMD3<Float>, footLeftVelocity: SIMD3<Float>, footRightVelocity: SIMD3<Float>, hipVelocity: SIMD3<Float>) -> MotionFeature {
         let trajPos = predictTrajectory(currentPosition: currentPosition, currentVelocity: currentVelocity, targetPosition: targetPosition)
         let trajDir = (1..<trajPos.count).map { i in
             let dir = trajPos[i] - trajPos[i - 1]
             return simd_length(dir) > Epsilon.position ? simd_normalize(dir) : SIMD3<Float>(1, 0, 0)
         }
         return MotionFeature(trajectoryPositions: trajPos, trajectoryDirections: trajDir, footLeftPosition: footLeftPosition, footRightPosition: footRightPosition, footLeftVelocity: footLeftVelocity, footRightVelocity: footRightVelocity, hipVelocity: hipVelocity)
     }

     func initializeOrUpdateInertialization(for id: String, targetTransform: Transform, currentTransform: Transform, previousTransform: Transform, deltaTime: Float, config: InertializationConfig, blendTime: Float? = nil) {
         var modConfig = config
         if let blend = blendTime { modConfig.blendTime = blend }
         if inertializationData[id]?.isActive ?? false { return }
         inertializationData[id] = initializeTransformInertialData(targetTransform: targetTransform, prevTransform: currentTransform, oldPrevTransform: previousTransform, deltaTime: deltaTime, config: modConfig)
     }

     func applyInertialization(for id: String, targetTransform: Transform, deltaTime: Float) -> Transform {
         guard var data = inertializationData[id], data.isActive else { return targetTransform }
         let result = applyTransformInertial(data: &data, targetTransform: targetTransform, deltaTime: deltaTime)
         inertializationData[id] = data
         if !data.isActive { inertializationData.removeValue(forKey: id) }
         return result
     }

     func getSkeletonInertializer(for id: String, config: InertializationConfig) -> SkeletonInertializer {
         if let existing = skeletonInertializers[id] { return existing }
         let newSkeleton = SkeletonInertializer(config: config)
         skeletonInertializers[id] = newSkeleton
         return newSkeleton
     }

     func initializeBonesForSkeleton(skeletonId: String, bones: [String: Transform], deltaTime: Float, config: InertializationConfig) {
         getSkeletonInertializer(for: skeletonId, config: config).initializeBones(targetTransforms: bones, deltaTime: deltaTime)
     }

     func updateBonesForSkeleton(skeletonId: String, bones: [String: Transform], deltaTime: Float) -> [String: Transform] {
         skeletonInertializers[skeletonId]?.update(targetTransforms: bones, deltaTime: deltaTime) ?? bones
     }

     func clearCaches() {
         springDamper.clearCache()
         lossFunction.clearCache()
         PolynomialCache.shared.clear()
         QuaternionCache.shared.clear()
     }
 }
 */
