import RealityKit
import simd

// MARK: - Constants for Numerical Stability

/// Small value thresholds for numerical stability
enum Epsilon {
    static let blendTime: Float = 0.00001  // Minimum meaningful blend time
    static let angle: Float = 0.0001       // Minimum meaningful rotation angle
    static let position: Float = 0.00001   // Minimum meaningful position offset
}

/// Clamp a value between min and max
@inline(__always) func clamp<T: Comparable>(_ value: T, _ min: T, _ max: T) -> T {
    return Swift.max(min, Swift.min(value, max))
}

// MARK: - Polynomial Coefficient Calculation and Evaluation

/// Computes polynomial coefficients for fifth-order interpolation with optional overshoot prevention.
/// - Parameters:
///   - x0: Initial offset value (position or angle)
///   - v0: Initial velocity
///   - tf: Desired blend time
///   - preventOvershoot: Whether to apply overshoot prevention (C3 feature)
/// - Returns: Polynomial coefficients and effective blend time
func computePolynomialCoefficients(x0: Float, v0: Float, tf: Float, preventOvershoot: Bool = true) -> (A: Float, B: Float, C: Float, a0: Float, effectiveTf: Float) {
    // Use cached result if available
    let key = PolynomialCacheKey(x0: x0, v0: v0, tf: tf, preventOvershoot: preventOvershoot)
    if let cachedResult = PolynomialCache.shared.cache[key] {
        return cachedResult
    }
    
    // Skip computation if initial offset is negligible
    if abs(x0) < Epsilon.position {
        return (0, 0, 0, 0, 0)
    }
    
    var adjustedTf = tf
    
    // Apply overshoot prevention (C3 feature)
    if preventOvershoot && v0 * x0 < 0 {
        // Calculate candidate blend time based on preventing overshoot
        let tfCandidate = abs(5 * x0 / v0)
        if tfCandidate > 0 {
            adjustedTf = min(adjustedTf, tfCandidate)
        }
    }
    
    // Handle very small blend times
    if adjustedTf < Epsilon.blendTime {
        return (0, 0, 0, 0, 0)
    }
    
    // Precompute powers of blend time for efficiency (O3 approach)
    let tf2 = adjustedTf * adjustedTf
    let tf3 = tf2 * adjustedTf
    let tf4 = tf3 * adjustedTf
    let tf5 = tf4 * adjustedTf
    
    // Compute the polynomial coefficients using O3's clear structure
    let a0 = (-8 * v0 * adjustedTf - 20 * x0) / (adjustedTf * adjustedTf)
    let A = -(a0 * tf2 + 6 * v0 * adjustedTf + 12 * x0) / (2 * tf5)
    let B = (3 * a0 * tf2 + 16 * v0 * adjustedTf + 30 * x0) / (2 * tf4)
    let C = -(3 * a0 * tf2 + 12 * v0 * adjustedTf + 20 * x0) / (2 * tf3)
    
    // Store in cache
    let result = (A, B, C, a0, adjustedTf)
    PolynomialCache.shared.cache[key] = result
    
    return result
}

/// Evaluates the polynomial interpolation at time t with improved efficiency.
/// - Parameters:
///   - t: Current time
///   - maxT: Maximum time (blend duration)
///   - A, B, C, a0: Polynomial coefficients
///   - v0: Initial velocity
///   - x0: Initial offset
/// - Returns: Interpolated offset at time t
@inline(__always) func evaluatePolynomial(t: Float, maxT: Float, A: Float, B: Float, C: Float, a0: Float, v0: Float, x0: Float) -> Float {
    // Clamp t to maxT to prevent extrapolation
    let clampedT = min(t, maxT)
    
    // Compute powers of t once (O3 approach)
    let t2 = clampedT * clampedT
    let t3 = t2 * clampedT
    let t4 = t3 * clampedT
    let t5 = t4 * clampedT
    
    // Evaluate the 5th-order polynomial in a single expression
    return A * t5 + B * t4 + C * t3 + (a0 / 2) * t2 + v0 * clampedT + x0
}

// MARK: - Quaternion Math Utilities

/// Converts a quaternion to its axis-angle representation with improved efficiency.
/// - Parameter q: Input quaternion
/// - Returns: Tuple of (axis, angle)
func quaternionToAxisAngle(_ q: simd_quatf) -> (SIMD3<Float>, Float) {
    // Use cache if available
    let cacheKey = QuaternionCacheKey(quaternion: q)
    if let cached = QuaternionCache.shared.cache[cacheKey] {
        return cached
    }
    
    // Ensure the quaternion is normalized
    let normalized = simd_normalize(q)
    
    // Extract the angle (clamping to handle numerical imprecision)
    let cosHalfAngle = clamp(normalized.real, -1.0, 1.0)
    let angle = 2.0 * acos(cosHalfAngle)
    
    // Handle the case where angle is very small (identity rotation)
    let sinHalfAngle = sqrt(1.0 - cosHalfAngle * cosHalfAngle)
    let result: (SIMD3<Float>, Float)
    if sinHalfAngle < Epsilon.angle {
        result = (SIMD3<Float>(1, 0, 0), 0)
    } else {
        // Extract and normalize the axis
        let axis = normalized.imag / sinHalfAngle
        result = (simd_normalize(axis), angle)
    }
    
    // Cache the result
    QuaternionCache.shared.cache[cacheKey] = result
    
    return result
}

/// Converts an axis-angle representation to a quaternion.
/// - Parameters:
///   - axis: Rotation axis (normalized)
///   - angle: Rotation angle in radians
/// - Returns: Quaternion representing the rotation
func axisAngleToQuaternion(axis: SIMD3<Float>, angle: Float) -> simd_quatf {
    // Ensure we're using a normalized axis
    let normalizedAxis = simd_normalize(axis)
    
    let halfAngle = angle * 0.5
    let sinHalf = sin(halfAngle)
    let cosHalf = cos(halfAngle)
    
    return simd_quatf(
        ix: normalizedAxis.x * sinHalf,
        iy: normalizedAxis.y * sinHalf,
        iz: normalizedAxis.z * sinHalf,
        r: cosHalf
    )
}

/// Ensures quaternion interpolation follows the shortest path.
/// - Parameters:
///   - q: Quaternion to potentially flip
///   - reference: Reference quaternion
/// - Returns: Potentially flipped quaternion to ensure shortest path
func ensureShortestPath(_ q: simd_quatf, reference: simd_quatf) -> simd_quatf {
    // Use the dot product to determine if we need to flip the quaternion
    if simd_dot(q.vector, reference.vector) < 0 {
        return simd_quatf(vector: -q.vector)
    }
    return q
}

