import RealityKit
import simd

// MARK: - Configuration Types

/// Different methods for inertialization.
enum InertializationMethod {
    /// Directional approach that preserves the direction of motion - used ny Gears of War, most common
    case magnitude
    /// Component-wise approach that interpolates each component separately.
    case direct
}

/// Different methods for position inertialization
enum PositionInertializationMethod {
    /// Use polynomial interpolation (original method)
    case polynomial
    /// Use physics-based spring-damper approach - to be used for position, more natural and follows physics
    /// the magnitude method is significantly cheaper in terms of computational resources compared to the spring damper approach. (3x)
    case springDamper
}

/// Configuration options for inertialization behavior.
struct InertializationConfig {
    /// Inertialization method to use.
    var method: InertializationMethod = .magnitude
    /// Method to use for position inertialization
    var positionMethod: PositionInertializationMethod = .polynomial
    
    /// Whether to apply overshoot prevention
    var preventOvershoot: Bool = true
    /// Blend time for the transition in seconds.
    var blendTime: Float = 0.5
    
    /// Threshold for position magnitude below which inertialization stops.
    var positionThreshold: Float = 0.001
    /// Threshold for rotation angle below which inertialization stops.
    var rotationThreshold: Float = 0.01
    
    /// Spring stiffness for spring-damper position inertialization
    var stiffness: Float = 10.0
    /// Damping coefficient for spring-damper position inertialization
    var damping: Float = 2.0
    /// Threshold for convergence in spring-damper system
    var convergenceThreshold: Float = 0.01
     
    /// Whether to use 3D features for motion matching
    var use3D: Bool = true
    
    /// Default configuration
    static let `default` = InertializationConfig()
    /// Fast transition configuration
    static let fast = InertializationConfig(blendTime: 0.3, positionThreshold: 0.002, rotationThreshold: 0.02)
    /// Smooth transition configuration
    static let smooth = InertializationConfig(blendTime: 1.0, positionThreshold: 0.0005, rotationThreshold: 0.005)
}

// MARK: - Vector (Translation) Inertialization

/// Protocol for vector inertialization data
protocol VectorInertializable {
    var isActive: Bool { get set }
}

/// Data structure for vector inertialization using magnitude method.
struct VectorInertialData: VectorInertializable {
    var direction: SIMD3<Float> // Unit vector of the initial offset.
    var initialMagnitude: Float // Magnitude of the initial difference.
    var velocity: Float // Scalar velocity computed from differences.
    var elapsedTime: Float // Time since inertialization started.
    var isActive: Bool // Indicates whether inertialization is active.
    var effectiveBlendTime: Float // Effective blend time after overshoot prevention.
    var A: Float // Polynomial coefficient A.
    var B: Float // Polynomial coefficient B.
    var C: Float // Polynomial coefficient C.
    var a0: Float // Polynomial coefficient a0.
}

/// Data structure for direct vector inertialization.
struct VectorDirectInertialData: VectorInertializable {
    var initialOffset: SIMD3<Float> // Initial offset vector from target.
    var velocity: SIMD3<Float> // Component-wise velocity.
    var elapsedTime: Float // Time since inertialization started.
    var isActive: Bool // Indicates whether inertialization is active.
    var effectiveBlendTime: Float // Effective blend time.
    var A: SIMD3<Float> // Polynomial coefficients A per component.
    var B: SIMD3<Float> // Polynomial coefficients B per component.
    var C: SIMD3<Float> // Polynomial coefficients C per component.
    var a0: SIMD3<Float> // Polynomial coefficients a0 per component.
}

/// Initialize vector inertialization with magnitude method
func initializeVectorInertialDataMagnitude(
    pTarget: SIMD3<Float>,
    pPrev: SIMD3<Float>,
    pOldPrev: SIMD3<Float>,
    deltaTime: Float,
    config: InertializationConfig
) -> VectorInertialData {
    // Calculate initial offset: direction from previous to target
    let x0 = pTarget - pPrev
    let xMinus1 = pPrev - pOldPrev // Previous motion
    let magX0 = simd_length(x0) // Magnitude of initial offset
    
    // Early exit for zero movement
    if magX0 < Epsilon.position {
        return VectorInertialData(
            direction: SIMD3<Float>(1, 0, 0),
            initialMagnitude: 0,
            velocity: 0,
            elapsedTime: 0,
            isActive: false,
            effectiveBlendTime: 0,
            A: 0, B: 0, C: 0, a0: 0
        )
    }
    
    // Calculate direction and extract parallel component of previous motion
    let direction = x0 / magX0
    let parallelMagnitude = simd_dot(xMinus1, direction)
    let xMinus1Parallel = direction * parallelMagnitude
    let magXMinus1Parallel = simd_length(xMinus1Parallel)
    
    // Calculate velocity along the offset direction
    let velocity = (magX0 - magXMinus1Parallel) / deltaTime
    
    // Calculate polynomial coefficients with overshoot prevention option
    let (A, B, C, a0, effectiveTf) = computePolynomialCoefficients(
        x0: magX0,
        v0: velocity,
        tf: config.blendTime,
        preventOvershoot: config.preventOvershoot
    )
    
    return VectorInertialData(
        direction: direction,
        initialMagnitude: magX0,
        velocity: velocity,
        elapsedTime: 0.0,
        isActive: effectiveTf > 0,
        effectiveBlendTime: effectiveTf,
        A: A,
        B: B,
        C: C,
        a0: a0
    )
}

/// Initialize vector inertialization with direct method
func initializeVectorInertialDataDirect(
    pTarget: SIMD3<Float>,
    pPrev: SIMD3<Float>,
    pOldPrev: SIMD3<Float>,
    deltaTime: Float,
    config: InertializationConfig
) -> VectorDirectInertialData {
    // Order is important: compute offset from target to previous
    let x0 = pPrev - pTarget // Initial offset (prev minus target)
    let xMinus1 = pOldPrev - pPrev // Previous motion
    
    // Calculate velocity: change in offset over time
    let velocity = (x0 - xMinus1) / deltaTime
    
    // Skip computation if there's no significant movement
    guard simd_length(x0) >= Epsilon.position else {
        return VectorDirectInertialData(
            initialOffset: .zero,
            velocity: .zero,
            elapsedTime: 0.0,
            isActive: false,
            effectiveBlendTime: 0,
            A: .zero, B: .zero, C: .zero, a0: .zero
        )
    }
    
    // Compute coefficients for each component (x, y, z)
    var A = SIMD3<Float>(repeating: 0)
    var B = SIMD3<Float>(repeating: 0)
    var C = SIMD3<Float>(repeating: 0)
    var a0 = SIMD3<Float>(repeating: 0)
    var effectiveTf: Float = 0
    var isActive = false
    
    for i in 0..<3 {
        // Apply with overshoot prevention if configured
        let (A_i, B_i, C_i, a0_i, tf_i) = computePolynomialCoefficients(
            x0: x0[i],
            v0: velocity[i],
            tf: config.blendTime,
            preventOvershoot: config.preventOvershoot
        )
        A[i] = A_i
        B[i] = B_i
        C[i] = C_i
        a0[i] = a0_i
        if tf_i > 0 {
            effectiveTf = max(effectiveTf, tf_i)
            isActive = true
        }
    }
    
    return VectorDirectInertialData(
        initialOffset: x0,
        velocity: velocity,
        elapsedTime: 0.0,
        isActive: isActive,
        effectiveBlendTime: effectiveTf,
        A: A,
        B: B,
        C: C,
        a0: a0
    )
}

/// Apply vector inertialization with magnitude method
func applyVectorInertialMagnitude(
    data: inout VectorInertialData,
    pTarget: SIMD3<Float>,
    deltaTime: Float,
    config: InertializationConfig
) -> SIMD3<Float> {
    if !data.isActive { return pTarget }
    
    data.elapsedTime += deltaTime
    
    // Use the inline polynomial evaluation function
    let xt = evaluatePolynomial(
        t: data.elapsedTime,
        maxT: data.effectiveBlendTime,
        A: data.A,
        B: data.B,
        C: data.C,
        a0: data.a0,
        v0: data.velocity,
        x0: data.initialMagnitude
    )
    
    // Check if inertialization is complete
    if data.elapsedTime >= data.effectiveBlendTime || xt < config.positionThreshold {
        data.isActive = false
        return pTarget
    }
    
    // Ensure the magnitude is not negative
    let currentMagnitude = max(xt, 0.0)
    
    // Apply the offset to the target position
    return pTarget + data.direction * currentMagnitude
}

/// Apply vector inertialization with direct method
func applyVectorInertialDirect(
    data: inout VectorDirectInertialData,
    pTarget: SIMD3<Float>,
    deltaTime: Float,
    config: InertializationConfig
) -> SIMD3<Float> {
    if !data.isActive { return pTarget }
    
    data.elapsedTime += deltaTime
    
    // Component-wise evaluation using SIMD operations
    let t = min(data.elapsedTime, data.effectiveBlendTime)
    let t2 = t * t
    let t3 = t2 * t
    let t4 = t3 * t
    let t5 = t4 * t
    
    // Evaluate the polynomial for all components at once
    // Break down the complex expression into smaller parts
    let term1 = data.A * t5
    let term2 = data.B * t4
    let term3 = data.C * t3
    let term4 = (data.a0 / 2) * t2
    let term5 = data.velocity * t
        
    // Combine the terms
    let xt = term1 + term2 + term3 + term4 + term5 + data.initialOffset
    
    // Check completion criteria
    let magnitude = simd_length(xt)
    if data.elapsedTime >= data.effectiveBlendTime || magnitude < config.positionThreshold {
        data.isActive = false
        return pTarget
    }
    
    // Return the interpolated position
    return pTarget + xt
}

// MARK: - Quaternion (Rotation) Inertialization

/// Protocol for quaternion inertialization data
protocol QuaternionInertializable {
    var isActive: Bool { get set } // whether an inertialization process is currently active
}

/// Data structure for quaternion inertialization using magnitude method.
struct QuaternionInertialData: QuaternionInertializable {
    var axis: SIMD3<Float> // Rotation axis.
    var initialAngle: Float // Initial angle.
    var angularVelocity: Float // Angular velocity.
    var elapsedTime: Float // Elapsed time.
    var isActive: Bool // Active state: whether an inertialization process is currently active
    var effectiveBlendTime: Float // Effective blend time.
    var A: Float // Polynomial coefficient A.
    var B: Float // Polynomial coefficient B.
    var C: Float // Polynomial coefficient C.
    var a0: Float // Polynomial coefficient a0.
}

/// Data structure for quaternion inertialization using direct method.
struct QuaternionDirectInertialData: QuaternionInertializable {
    var initialOffset: simd_quatf // Initial quaternion offset.
    var velocity: SIMD4<Float> // Component-wise velocity.
    var elapsedTime: Float // Elapsed time.
    var isActive: Bool // Active state.
    var effectiveBlendTime: Float // Effective blend time.
    var A: SIMD4<Float> // Polynomial coefficients A.
    var B: SIMD4<Float> // Polynomial coefficients B.
    var C: SIMD4<Float> // Polynomial coefficients C.
    var a0: SIMD4<Float> // Polynomial coefficients a0.
}

/// Initialize quaternion inertialization with magnitude method
func initializeQuaternionInertialDataMagnitude(
    qTarget: simd_quatf,
    qPrev: simd_quatf,
    qOldPrev: simd_quatf,
    deltaTime: Float,
    config: InertializationConfig
) -> QuaternionInertialData {
    // Normalize and align quaternions to ensure shortest path
    let qTargetNorm = simd_normalize(qTarget)
    let qPrevAligned = ensureShortestPath(simd_normalize(qPrev), reference: qTargetNorm)
    let qOldPrevAligned = ensureShortestPath(simd_normalize(qOldPrev), reference: qPrevAligned)
    
    // Calculate the difference quaternions:
    // q0 represents the rotation from previous to target
    let q0 = qTargetNorm * qPrevAligned.inverse
    
    // qMinus1 represents the rotation from old-previous to previous
    let qMinus1 = qPrevAligned * qOldPrevAligned.inverse
    
    // Convert to axis-angle representation
    let (axis0, angle0) = quaternionToAxisAngle(q0)
    
    // Skip computation if angle is very small
    if angle0 < Epsilon.angle {
        return QuaternionInertialData(
            axis: SIMD3<Float>(1, 0, 0),
            initialAngle: 0,
            angularVelocity: 0,
            elapsedTime: 0,
            isActive: false,
            effectiveBlendTime: 0,
            A: 0, B: 0, C: 0, a0: 0
        )
    }
    
    // Extract the twist component (rotation around the same axis)
    let thetaMinus1 = extractTwistAroundAxis(qMinus1, axis: axis0)
    
    // Calculate angular velocity
    let omega0 = (angle0 - thetaMinus1) / deltaTime
    
    // Compute interpolation coefficients with overshoot prevention
    let (A, B, C, a0, effectiveTf) = computePolynomialCoefficients(
        x0: angle0,
        v0: omega0,
        tf: config.blendTime,
        preventOvershoot: config.preventOvershoot
    )
    
    return QuaternionInertialData(
        axis: axis0,
        initialAngle: angle0,
        angularVelocity: omega0,
        elapsedTime: 0.0,
        isActive: effectiveTf > 0,
        effectiveBlendTime: effectiveTf,
        A: A,
        B: B,
        C: C,
        a0: a0
    )
}

/// Initialize quaternion inertialization with direct method
func initializeQuaternionInertialDataDirect(
    qTarget: simd_quatf,
    qPrev: simd_quatf,
    qOldPrev: simd_quatf,
    deltaTime: Float,
    config: InertializationConfig
) -> QuaternionDirectInertialData {
    // Normalize and align quaternions
    let qTargetNorm = simd_normalize(qTarget)
    let qPrevAligned = ensureShortestPath(simd_normalize(qPrev), reference: qTargetNorm)
    let qOldPrevAligned = ensureShortestPath(simd_normalize(qOldPrev), reference: qPrevAligned)
    
    // Calculate quaternion differences (note the order for direct method)
    let q0 = qPrevAligned * qTargetNorm.inverse
    let qMinus1 = qOldPrevAligned * qPrevAligned.inverse
    
    // Skip if there's no significant rotation
    if abs(q0.real - 1.0) < Epsilon.angle {
        return QuaternionDirectInertialData(
            initialOffset: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
            velocity: SIMD4<Float>(0, 0, 0, 0),
            elapsedTime: 0.0,
            isActive: false,
            effectiveBlendTime: 0,
            A: SIMD4<Float>(0, 0, 0, 0),
            B: SIMD4<Float>(0, 0, 0, 0),
            C: SIMD4<Float>(0, 0, 0, 0),
            a0: SIMD4<Float>(0, 0, 0, 0)
        )
    }
    
    // Calculate component-wise velocity for each quaternion component
    let velocity = (q0.vector - qMinus1.vector) / deltaTime
    
    // Compute coefficients for each component (x, y, z, w)
    var A = SIMD4<Float>(repeating: 0)
    var B = SIMD4<Float>(repeating: 0)
    var C = SIMD4<Float>(repeating: 0)
    var a0 = SIMD4<Float>(repeating: 0)
    var effectiveTf: Float = 0
    var isActive = false
    
    for i in 0..<4 {
        let (A_i, B_i, C_i, a0_i, tf_i) = computePolynomialCoefficients(
            x0: q0.vector[i],
            v0: velocity[i],
            tf: config.blendTime,
            preventOvershoot: config.preventOvershoot
        )
        A[i] = A_i
        B[i] = B_i
        C[i] = C_i
        a0[i] = a0_i
        if tf_i > 0 {
            effectiveTf = max(effectiveTf, tf_i)
            isActive = true
        }
    }
    
    return QuaternionDirectInertialData(
        initialOffset: q0,
        velocity: velocity,
        elapsedTime: 0.0,
        isActive: isActive,
        effectiveBlendTime: effectiveTf,
        A: A,
        B: B,
        C: C,
        a0: a0
    )
}

/// Extract the twist angle (rotation about a given axis) from a quaternion.
func extractTwistAroundAxis(_ q: simd_quatf, axis: SIMD3<Float>) -> Float {
    // Normalize the axis
    let normalizedAxis = simd_normalize(axis)
    
    // Project the quaternion's imaginary part onto the axis
    let projection = simd_dot(q.imag, normalizedAxis)
    
    // Construct the twist quaternion
    let twistW = q.real
    let twistVector = normalizedAxis * projection
    
    // Compute the length for normalization
    let twistLength = sqrt(twistW * twistW + simd_length_squared(twistVector))
    
    // Guard against division by zero
    if twistLength < Epsilon.angle {
        return 0.0
    }
    
    // Create the normalized twist quaternion
    let twistQuat = simd_quatf(
        ix: twistVector.x / twistLength,
        iy: twistVector.y / twistLength,
        iz: twistVector.z / twistLength,
        r: twistW / twistLength
    )
    
    // Extract the angle
    let (_, twistAngle) = quaternionToAxisAngle(twistQuat)
    return twistAngle
}

/// Apply quaternion inertialization with magnitude method
func applyQuaternionInertialMagnitude(
    data: inout QuaternionInertialData,
    qTarget: simd_quatf,
    deltaTime: Float,
    config: InertializationConfig
) -> simd_quatf {
    guard data.isActive else { return qTarget }
    
    data.elapsedTime += deltaTime
    
    let theta_t = evaluatePolynomial(
        t: data.elapsedTime,
        maxT: data.effectiveBlendTime,
        A: data.A, B: data.B, C: data.C, a0: data.a0,
        v0: data.angularVelocity, x0: data.initialAngle
    )
    
    if data.elapsedTime >= data.effectiveBlendTime || theta_t < config.rotationThreshold {
        data.isActive = false
        return qTarget
    }
    
    return qTarget * axisAngleToQuaternion(axis: data.axis, angle: max(theta_t, 0.0))
}

/// Apply quaternion inertialization with direct method
func applyQuaternionInertialDirect(
    data: inout QuaternionDirectInertialData,
    qTarget: simd_quatf,
    deltaTime: Float,
    config: InertializationConfig
) -> simd_quatf {
    if !data.isActive { return qTarget }
    
    data.elapsedTime += deltaTime
    
    // Evaluate polynomial for each component
    let t = min(data.elapsedTime, data.effectiveBlendTime)
    let t2 = t * t
    let t3 = t2 * t
    let t4 = t3 * t
    let t5 = t4 * t
    
    // Calculate the quaternion components using polynomial interpolation
    // Break down the complex expression into smaller parts
        let term1 = data.A * t5
        let term2 = data.B * t4
        let term3 = data.C * t3
        let term4 = (data.a0 / 2) * t2
        let term5 = data.velocity * t
        
        // Combine the terms
        let qt = term1 + term2 + term3 + term4 + term5 + data.initialOffset.vector
        
    
    // Create quaternion from interpolated components
    let offsetQuat = simd_quatf(vector: qt)
    
    // Check if the rotation is small enough to complete
    let angle = 2.0 * acos(clamp(offsetQuat.vector.w, -1.0, 1.0))
    if data.elapsedTime >= data.effectiveBlendTime || angle < config.rotationThreshold {
        data.isActive = false
        return qTarget
    }
    
    // Apply the rotation (ensure we normalize to prevent drift)
    return simd_normalize(qTarget * offsetQuat)
}

// MARK: - Combined Transform Inertialization

/// Enum to store inertial data with proper type information
enum InertialData {
    // For the magnitude-based method
    case magnitude(position: VectorInertialData, rotation: QuaternionInertialData)
    
    // For the component-wise method
    case direct(position: VectorDirectInertialData, rotation: QuaternionDirectInertialData)
    
    // For spring-damper method (C3 extension)
    case springDamper(position: SpringDamperPosition, rotation: QuaternionInertialData)
    
    var isActive: Bool {
        switch self {
        case .magnitude(let position, let rotation):
            return position.isActive || rotation.isActive
        case .direct(let position, let rotation):
            return position.isActive || rotation.isActive
        case .springDamper(let position, let rotation):
            return position.isActive || rotation.isActive
        }
    }
}

/// Data structure for combined transform inertialization.
struct TransformInertialData {
    var data: InertialData
    var config: InertializationConfig
    
    var isActive: Bool {
        return data.isActive
    }
}

// MARK: - Spring-Damper Position Inertialization (Motion Matching paper extension)

/// State for a single component in spring-damper system
class SpringDamperState {
    private let stiffness: Float
    private let damping: Float
    var current: Float
    var velocity: Float
    var target: Float
    
    init(stiffness: Float, damping: Float, current: Float, velocity: Float, target: Float) {
        self.stiffness = stiffness
        self.damping = damping
        self.current = current
        self.velocity = velocity
        self.target = target
    }
    
    func update(deltaTime: Float) {
        let displacement = current - target
        let acceleration = -stiffness * displacement - damping * velocity
        velocity += acceleration * deltaTime
        current += velocity * deltaTime
    }
    
    func isConverged(threshold: Float) -> Bool {
        return abs(current - target) < threshold
    }
}

/// Spring-damper position interpolation system
class SpringDamperPosition {
    var states: [SpringDamperState] = []
    var isActive: Bool = true
    
    init(config: InertializationConfig, current: SIMD3<Float>, velocity: SIMD3<Float>, target: SIMD3<Float>) {
        states = [
            SpringDamperState(stiffness: config.stiffness, damping: config.damping,
                              current: current.x, velocity: velocity.x, target: target.x),
            SpringDamperState(stiffness: config.stiffness, damping: config.damping,
                              current: current.y, velocity: velocity.y, target: target.y),
            SpringDamperState(stiffness: config.stiffness, damping: config.damping,
                              current: current.z, velocity: velocity.z, target: target.z)
        ]
    }
    
    func update(deltaTime: Float, threshold: Float) {
        for state in states {
            state.update(deltaTime: deltaTime)
        }
        
        // Check if all states have converged
        isActive = !states.allSatisfy { $0.isConverged(threshold: threshold) }
    }
    
    func getPosition() -> SIMD3<Float> {
        return SIMD3<Float>(states[0].current, states[1].current, states[2].current)
    }
}

// MARK: - Transform Inertialization

/// Transform type definition
struct Transform {
    var translation: SIMD3<Float>
    var rotation: simd_quatf
    var scale: SIMD3<Float>
    
    static var identity: Transform {
        return Transform(
            translation: SIMD3<Float>(0, 0, 0),
            rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0)),
            scale: SIMD3<Float>(1, 1, 1)
        )
    }
}

/// Initialize transform inertialization data
func initializeTransformInertialData(
    targetTransform: Transform,
    prevTransform: Transform,
    oldPrevTransform: Transform,
    deltaTime: Float,
    config: InertializationConfig
) -> TransformInertialData {
    let pTarget = targetTransform.translation
    let pPrev = prevTransform.translation
    let pOldPrev = oldPrevTransform.translation
    
    let qTarget = targetTransform.rotation
    let qPrev = prevTransform.rotation
    let qOldPrev = oldPrevTransform.rotation
    
    // Handle position inertialization based on selected method
    var data: InertialData
    
    // Initialize quaternion data for rotation (always using polynomial method)
    let quaternionData: QuaternionInertialData
    let quaternionDataDirect: QuaternionDirectInertialData
    
    if config.method == .magnitude {
        quaternionData = initializeQuaternionInertialDataMagnitude(
            qTarget: qTarget,
            qPrev: qPrev,
            qOldPrev: qOldPrev,
            deltaTime: deltaTime,
            config: config
        )
        
        if config.positionMethod == .polynomial {
            // Original polynomial-based position inertialization
            let vectorData = initializeVectorInertialDataMagnitude(
                pTarget: pTarget,
                pPrev: pPrev,
                pOldPrev: pOldPrev,
                deltaTime: deltaTime,
                config: config
            )
            data = .magnitude(position: vectorData, rotation: quaternionData)
        } else {
            // Spring-damper position inertialization
            let velocity = (pPrev - pOldPrev) / deltaTime
            let springDamperData = SpringDamperPosition(
                config: config,
                current: pPrev,
                velocity: velocity,
                target: pTarget
            )
            data = .springDamper(position: springDamperData, rotation: quaternionData)
        }
    } else {
        // Direct method
        quaternionDataDirect = initializeQuaternionInertialDataDirect(
            qTarget: qTarget,
            qPrev: qPrev,
            qOldPrev: qOldPrev,
            deltaTime: deltaTime,
            config: config
        )
        
        // For direct method, we only use polynomial interpolation
        let vectorDataDirect = initializeVectorInertialDataDirect(
            pTarget: pTarget,
            pPrev: pPrev,
            pOldPrev: pOldPrev,
            deltaTime: deltaTime,
            config: config
        )
        data = .direct(position: vectorDataDirect, rotation: quaternionDataDirect)
    }
    
    return TransformInertialData(data: data, config: config)
}

/// Apply transform inertialization
func applyTransformInertial(
    data: inout TransformInertialData,
    targetTransform: Transform,
    deltaTime: Float //update deltaTime
) -> Transform {
    if !data.isActive { return targetTransform }
    
    var pOut = targetTransform.translation
    var qOut = targetTransform.rotation
    
    // Apply position and rotation inertialization based on method
    switch data.data {
    case .magnitude(var position, var rotation):
        // Apply magnitude-based interpolation
        pOut = applyVectorInertialMagnitude(
            data: &position,
            pTarget: targetTransform.translation,
            deltaTime: deltaTime,
            config: data.config
        )
        
        qOut = applyQuaternionInertialMagnitude(
            data: &rotation,
            qTarget: targetTransform.rotation,
            deltaTime: deltaTime,
            config: data.config
        )
        
        // Update the data
        data.data = .magnitude(position: position, rotation: rotation)
        
    case .direct(var position, var rotation):
        // Apply component-wise interpolation
        pOut = applyVectorInertialDirect(
            data: &position,
            pTarget: targetTransform.translation,
            deltaTime: deltaTime,
            config: data.config
        )
        
        qOut = applyQuaternionInertialDirect(
            data: &rotation,
            qTarget: targetTransform.rotation,
            deltaTime: deltaTime,
            config: data.config
        )
        
        // Update the data
        data.data = .direct(position: position, rotation: rotation)
        
    case .springDamper(let position, var rotation):
        // Apply spring-damper position interpolation
        position.update(deltaTime: deltaTime, threshold: data.config.convergenceThreshold)
        
        if position.isActive {
            pOut = position.getPosition()
        }
        
        qOut = applyQuaternionInertialMagnitude(
            data: &rotation,
            qTarget: targetTransform.rotation,
            deltaTime: deltaTime,
            config: data.config
        )
        
        // Update the data
        data.data = .springDamper(position: position, rotation: rotation)
    }
    
    // Create the result transform
    var resultTransform = targetTransform
    resultTransform.translation = pOut
    resultTransform.rotation = qOut
    
    return resultTransform
}
