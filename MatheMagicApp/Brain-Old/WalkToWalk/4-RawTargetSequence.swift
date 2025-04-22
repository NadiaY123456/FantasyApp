//  4-TargetSequence.swift
//  AnimLib
//

// Construct sequence elements for target. Mark not filled.
import CoreLib

func constructRawTargetSequence(
    targetAnimations: [String: (startCriticalPoseIndex: Int, endCriticalPoseIndex: Int)],
    dataManager: DataManager
) -> [AnimationSequenceElement]? {
    for (animationName, (startCriticalPoseIndex, endCriticalPoseIndex)) in targetAnimations {
        guard let rawTargetSequence = constructAnimationSequenceForGivenAnimation(
            animationName: animationName,
            startCriticalPoseIndex: startCriticalPoseIndex,
            endCriticalPoseIndex: endCriticalPoseIndex, // if optional, search till the end or completes full loop
            isFilledOut: false,
            dataManager: dataManager
        ) else {
            AppLogger.shared.error("🧠 Error: Could not construct raw target sequence for \(animationName). Proceeding to the next candidate if any.")
            continue
        }
        return rawTargetSequence
    }
    
    AppLogger.shared.error("🧠 Error: Could not construct raw target sequence for any of the target animations.")
    return nil // Return an empty array if no valid sequence was found.
}

    
