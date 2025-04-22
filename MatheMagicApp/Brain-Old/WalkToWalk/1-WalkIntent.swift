//
//  WalkIntent.swift
//  AnimLib
//
import CoreLib
import simd




func determineTravelTargets() -> [TravelTarget] {
    // set travel targets
    var travelTargets: [TravelTarget] = []

    // set to transition to idle for now // TODO: make correct. For debugging purposes now.
    let idleTarget = TravelTarget(
        priority: 0.5,
        urgency: 0.5,
        inPlace: true, // location, rotation and id default to nil
        isTransit: false
    )

    // set to transition to walk for now //
    let walkTarget = TravelTarget(
        priority: 0.5,
        urgency: 0.5,
        inPlace: false, // location, rotation and id default to nil
        isTransit: true
    )

    if moveTarget == "walkTarget" {
        travelTargets.append(walkTarget)
    } else if moveTarget == "idleTarget" {
        travelTargets.append(idleTarget)
    }
    return travelTargets
}


func createMoveDirective(travelTargets: [TravelTarget], direction: JoystickDirection) -> MoveDirective {
    let targetMoveType = createTargetMoveType(travelTargets: travelTargets, direction: direction)
    
    var moveDirective = MoveDirective(
        moveType: targetMoveType,
        changeOrientationQuat: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 0, 1)),
        strideLengthRange: nil,
        moodArray: nil
    
    )
    switch targetMoveType {
    case .walk:
        moveDirective = determineMoveDirective(targetMoveType: targetMoveType, direction: direction)
    default:
        break
    }
    
    return moveDirective
}
/// Creates a target move type based on the current travel target and joystick direction.
func createTargetMoveType(travelTargets: [TravelTarget], direction: JoystickDirection) -> MoveType {
    guard let currentTarget = travelTargets.first else {
        AppLogger.shared.error("Error: No travelTarget found. Need to populate the target array")
        return .idle
    }

    switch currentTarget.inPlace {
    case false:
        return .walk
    case true:
        return .idle
    }
}

/// Determines the walking directive based on joystick direction.
func determineMoveDirective(targetMoveType: MoveType, direction: JoystickDirection) -> MoveDirective {
    switch direction {
    case .left:
        return MoveDirective (
            moveType: targetMoveType,
            changeOrientationQuat: simd_quatf(angle: -90 * (.pi / 180), axis: SIMD3<Float>(0, 1, 0)),
            strideLengthRange: nil, // no limitations
            moodArray: nil // Extend later if needed (or change to [Any] if required)
        )
    case .right:
        return MoveDirective (
            moveType: targetMoveType,
            changeOrientationQuat: simd_quatf(angle: 90 * (.pi / 180), axis: SIMD3<Float>(0, 1, 0)),
            strideLengthRange: nil, // no limitations
            moodArray: nil // Extend later if needed (or change to [Any] if required)
        )
    case .forward:
        return MoveDirective (
            moveType: targetMoveType,
            changeOrientationQuat: nil,
            strideLengthRange: [80,90],
            moodArray: nil //
        )
    case .back:
        return MoveDirective (
            moveType: targetMoveType,
            changeOrientationQuat: nil,
            strideLengthRange: [60,70],
            moodArray: nil //
        )
    case .none:
        return MoveDirective (
            moveType: targetMoveType,
            changeOrientationQuat: nil,
            strideLengthRange: nil,
            moodArray: nil //
        )
    }
}
