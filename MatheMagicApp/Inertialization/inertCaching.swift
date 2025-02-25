import RealityKit
import simd

// MARK: - Polynomial Coefficient Cache

/// Polynomial coefficient cache key with O3-style clean structure
/// but preserving C3's preventOvershoot parameter
struct PolynomialCacheKey: Hashable {
    let x0: Float
    let v0: Float 
    let tf: Float
    let preventOvershoot: Bool
    
    init(x0: Float, v0: Float, tf: Float, preventOvershoot: Bool = true) {
        self.x0 = x0
        self.v0 = v0
        self.tf = tf
        self.preventOvershoot = preventOvershoot
    }
}

/// Centralized cache for polynomial coefficients with O3's clean approach
class PolynomialCache {
    /// Shared singleton instance
    static let shared = PolynomialCache()
    
    /// Private initializer for singleton pattern
    private init() {}
    
    /// Cache storage with explicit typing
    var cache: [PolynomialCacheKey: (A: Float, B: Float, C: Float, a0: Float, effectiveTf: Float)] = [:]
    
    /// Clear the cache, keeping capacity for future entries
    func clear() {
        cache.removeAll(keepingCapacity: true)
    }
    
    /// Get cached value or compute if not available
    func getOrCompute(x0: Float, v0: Float, tf: Float, preventOvershoot: Bool = true) -> (A: Float, B: Float, C: Float, a0: Float, effectiveTf: Float) {
        let key = PolynomialCacheKey(x0: x0, v0: v0, tf: tf, preventOvershoot: preventOvershoot)
        if let cached = cache[key] {
            return cached
        }
        
        // If not in cache, compute and store the result
        let result = computePolynomialCoefficients(x0: x0, v0: v0, tf: tf, preventOvershoot: preventOvershoot)
        cache[key] = result
        return result
    }
}

// MARK: - Quaternion Cache

/// Quaternion axis-angle cache key with improved structure
struct QuaternionCacheKey: Hashable {
    let qReal: Float
    let qImagX: Float
    let qImagY: Float
    let qImagZ: Float
    
    init(quaternion: simd_quatf) {
        self.qReal = quaternion.real
        self.qImagX = quaternion.imag.x
        self.qImagY = quaternion.imag.y
        self.qImagZ = quaternion.imag.z
    }
}

/// Centralized cache for quaternion operations
class QuaternionCache {
    /// Shared singleton instance
    static let shared = QuaternionCache()
    
    /// Private initializer for singleton pattern
    private init() {}
    
    /// Cache storage with explicit typing for axis-angle pairs
    var cache: [QuaternionCacheKey: (SIMD3<Float>, Float)] = [:]
    
    /// Clear the cache, keeping capacity for future entries
    func clear() {
        cache.removeAll(keepingCapacity: true)
    }
    
    /// Get cached axis-angle or compute if not available
    func getOrComputeAxisAngle(quaternion: simd_quatf) -> (SIMD3<Float>, Float) {
        let key = QuaternionCacheKey(quaternion: quaternion)
        if let cached = cache[key] {
            return cached
        }
        
        // If not in cache, compute and store the result
        let normalized = simd_normalize(quaternion)
        let cosHalfAngle = clamp(normalized.real, -1.0, 1.0)
        let angle = 2.0 * acos(cosHalfAngle)
        
        let sinHalfAngle = sqrt(1.0 - cosHalfAngle * cosHalfAngle)
        let result: (SIMD3<Float>, Float)
        
        if sinHalfAngle < Epsilon.angle {
            result = (SIMD3<Float>(1, 0, 0), 0)
        } else {
            let axis = normalized.imag / sinHalfAngle
            result = (simd_normalize(axis), angle)
        }
        
        cache[key] = result
        return result
    }
}

// MARK: - Spring Damper System Cache

/// Cache for spring damper trajectories
class SpringDamperCache {
    /// Shared singleton instance
    static let shared = SpringDamperCache()
    
    /// Private initializer for singleton pattern
    private init() {}
    
    /// Cache structure optimized for trajectory lookups
    private var trajectoryCache: [String: [SIMD3<Float>]] = [:]
    
    /// Get cached trajectory or return nil if not available
    func getCachedTrajectory(currentPosition: SIMD3<Float>, 
                           currentVelocity: SIMD3<Float>,
                           targetPosition: SIMD3<Float>,
                           timePoints: [Float]) -> [SIMD3<Float>]? {
        // Generate a cache key
        let key = "\(currentPosition),\(currentVelocity),\(targetPosition),\(timePoints)"
        return trajectoryCache[key]
    }
    
    /// Store a computed trajectory
    func cacheTrajectory(currentPosition: SIMD3<Float>, 
                        currentVelocity: SIMD3<Float>,
                        targetPosition: SIMD3<Float>,
                        timePoints: [Float],
                        trajectory: [SIMD3<Float>]) {
        // Generate a cache key
        let key = "\(currentPosition),\(currentVelocity),\(targetPosition),\(timePoints)"
        
        // Limit cache size
        if trajectoryCache.count > 100 {
            trajectoryCache.removeAll(keepingCapacity: true)
        }
        
        trajectoryCache[key] = trajectory
    }
    
    /// Clear the cache
    func clear() {
        trajectoryCache.removeAll(keepingCapacity: true)
    }
}

// MARK: - Motion Matching Distance Cache

/// Cache for motion feature distance calculations
class MotionDistanceCache {
    /// Shared singleton instance
    static let shared = MotionDistanceCache()
    
    /// Private initializer for singleton pattern
    private init() {}
    
    /// Cache for distance calculations between motion features
    private var distanceCache: [String: Float] = [:]
    
    /// Get cached distance or return nil if not available
    func getCachedDistance(query: Int, candidate: Int, use3D: Bool) -> Float? {
        let key = "\(query),\(candidate),\(use3D)"
        return distanceCache[key]
    }
    
    /// Store a computed distance
    func cacheDistance(query: Int, candidate: Int, use3D: Bool, distance: Float) {
        let key = "\(query),\(candidate),\(use3D)"
        
        // Limit cache size
        if distanceCache.count > 1000 {
            distanceCache.removeAll(keepingCapacity: true)
        }
        
        distanceCache[key] = distance
    }
    
    /// Clear the cache
    func clear() {
        distanceCache.removeAll(keepingCapacity: true)
    }
}

// MARK: - Global Cache Management

/// Centralized cache management for the entire animation system
class CacheManager {
    /// Shared singleton instance
    static let shared = CacheManager()
    
    /// Private initializer for singleton pattern
    private init() {}
    
    /// Clear all caches in the system
    func clearAllCaches() {
        PolynomialCache.shared.clear()
        QuaternionCache.shared.clear()
        SpringDamperCache.shared.clear()
        MotionDistanceCache.shared.clear()
    }
    
    /// Clear specific caches by type
    func clearCache(type: CacheType) {
        switch type {
        case .polynomial:
            PolynomialCache.shared.clear()
        case .quaternion:
            QuaternionCache.shared.clear()
        case .springDamper:
            SpringDamperCache.shared.clear()
        case .motionDistance:
            MotionDistanceCache.shared.clear()
        }
    }
    
    /// Types of caches in the system
    enum CacheType {
        case polynomial
        case quaternion
        case springDamper
        case motionDistance
    }
}

/* G3 version
 import Foundation
 import simd

 /// Cache key for polynomial coefficients
 struct PolynomialCacheKey: Hashable {
     let x0: Float
     let v0: Float
     let tf: Float
     let preventOvershoot: Bool  // Retained from C3 for configurability
 }

 /// Centralized cache for polynomial coefficients
 class PolynomialCache {
     static let shared = PolynomialCache()
     private var cache: [PolynomialCacheKey: (A: Float, B: Float, C: Float, a0: Float, effectiveTf: Float)] = [:]

     private init() {}

     func get(_ key: PolynomialCacheKey) -> (A: Float, B: Float, C: Float, a0: Float, effectiveTf: Float)? {
         cache[key]
     }

     func set(key: PolynomialCacheKey, value: (A: Float, B: Float, C: Float, a0: Float, effectiveTf: Float)) {
         cache[key] = value
     }

     func clear() {
         cache.removeAll(keepingCapacity: true)
     }
 }

 /// Cache key for quaternion axis-angle conversions
 struct QuaternionCacheKey: Hashable {
     let qReal: Float
     let qImagX: Float
     let qImagY: Float
     let qImagZ: Float

     init(quaternion: simd_quatf) {
         self.qReal = quaternion.real
         self.qImagX = quaternion.imag.x
         self.qImagY = quaternion.imag.y
         self.qImagZ = quaternion.imag.z
     }
 }

 /// Centralized cache for quaternion operations
 class QuaternionCache {
     static let shared = QuaternionCache()
     private var cache: [QuaternionCacheKey: (SIMD3<Float>, Float)] = [:]

     private init() {}

     func get(_ key: QuaternionCacheKey) -> (SIMD3<Float>, Float)? {
         cache[key]
     }

     func set(key: QuaternionCacheKey, value: (SIMD3<Float>, Float)) {
         cache[key] = value
     }

     func clear() {
         cache.removeAll(keepingCapacity: true)
     }
 }
 */
