//
//  3-TargetAnimation.swift
//  AnimLib
//

import CoreLib
import RealityKit

/// ** Determine target animations for walk-to-walk transition **
@MainActor func walkToWalkTargetAnimations(
    initAnimationSequenceElement: AnimationSequenceElement, // for the start Critical Pose
    moveDirective: MoveDirective,
    dataManager: DataManager
) -> [String: (startCriticalPoseIndex: Int, endCriticalPoseIndex: Int)]? {
    // narrow down the list of target animations: for newWalk seach for walk target animation names, otherwise use the current one.

    // TODO: Hack for now: changing to the new walk mood only if moveDirective.mood is non-empty
    var targetAnimationCandidates = [initAnimationSequenceElement.animationName]

    if let desiredMood = moveDirective.moodArray {
        targetAnimationCandidates = dataManager.findAnimations(withOnlyMoveType: .walk)
    }

    // if current walk, determine if we need new turn animation. This is based on the degree of rotation over the step.
    // check that move directive specifies change in orientation greater than say 45 //TODO: hack, to insert the exact number
    if let desiredChangeOrientationQuat = moveDirective.changeOrientationQuat {
        let thresholdQuatLeft = simd_quatf(angle: -.pi / 4, axis: [0, 1, 0])
        let thresholdQuatRight = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])
        // if desiredChangeOrientationQuat is outside of thresholdQuatLeft to identity to threshold right
        if !isRotationWithin(rotation: desiredChangeOrientationQuat, maxRotation: thresholdQuatLeft), !isRotationWithin(rotation: desiredChangeOrientationQuat, maxRotation: identityTransform.rotation) {
            // search for animations that include walkToWalk transitions
            // TODO:
            AppLogger.shared.anim("Drastic turns are not implemented yet.")
        }
    }

    // for new stride, determine if we need new animation. TODO: hack. for now, assume that don't need.

    // find the target animations with correct start and end critical poses
    guard let matchingAnimations = walkToWalkTargetAnimationsCriticalPoseIndices(
        initAnimationSequenceElement: initAnimationSequenceElement, // for the start Critical Pose
        targetAnimationCandidates: targetAnimationCandidates, // narrowed down list of target animations
        dataManager: dataManager
    ) else {
        AppLogger.shared.error("Error: No matching animations found.")
        return nil
    }

    return matchingAnimations
}

// Pull Target animation names and its critical pose pairs starting with the end pose of InitSequence element
// The function first verifies that each candidate animation exists, has the correct start pose, and a matching target end pose after it. It then checks that the frame count between these poses exceeds a minimum threshold
@MainActor private func walkToWalkTargetAnimationsCriticalPoseIndices(
    initAnimationSequenceElement: AnimationSequenceElement, // for the start Critical Pose
    targetAnimationCandidates: [String], // narrowed down list of target animations
    dataManager: DataManager
) -> [String: (startCriticalPoseIndex: Int, endCriticalPoseIndex: Int)]? {
    let startPoseName = initAnimationSequenceElement.endPoseName

    // --- make sure that animation has enough segments. For example, it has a complete step ---
    let targetEndPoseType = endStartTransitionPoseType(startTransitionPoseType: startPoseName.poseType)

    // Determine targetEndPoseName
    guard let targetEndPoseName = findNextPoseName(
        startPoseName: startPoseName,
        endPoseType: targetEndPoseType,
        poseSequence: walkPoseSequence,
        accountForLooping: true
    ) else {
        AppLogger.shared.error("Error: No target end pose name found.")
        return [:]
    }

    // --- look for matching animations ----
    var matchingAnimations: [String: (startCriticalPoseIndex: Int, endCriticalPoseIndex: Int)]?

    for animationName in targetAnimationCandidates {
        // pull the data
        guard let animDataPoint = dataManager.getAnimDataPoint(for: animationName) else {
            AppLogger.shared.error("Error: Animation data not found for \(animationName)")
            continue
        }
        let isLooping = animDataPoint.isLoop

        // find first index with startPoseName in the target animation
        guard
            let startIndexCandidates = dataManager.getIndicesOfCriticalPose(for: animationName, matching: startPoseName),
            let startIndex = startIndexCandidates.first
        else {
            continue
        }

        // find the index after the first index (accounting for looping) for the end Critical Pose
        guard
            let endIndexCandidates = dataManager.getIndicesOfCriticalPose(for: animationName, matching: targetEndPoseName)
        else {
            continue
        }

        // check the smallest index after the start index
        var endIndex: Int?
        for candidate in endIndexCandidates {
            if candidate > startIndex {
                endIndex = candidate
                break
            }
        }
        // if did not find anything, continue searching from the beginning if looping
        if endIndex == nil, isLooping {
            for candidate in endIndexCandidates {
                if candidate < startIndex {
                    endIndex = candidate
                    break
                }
            }
        }

        // if no endIndex found, continue to the next animation
        guard let endIndex = endIndex else {
            continue
        }

        // check that animation has sufficient number of frames in it
        guard
            let totalFramesInTargetSequence = computeFrameCount(
                animationName: animationName,
                frameStart: animDataPoint.criticalPoses[startIndex].frame,
                frameEnd: animDataPoint.criticalPoses[endIndex].frame, // counts in frameEnd
                dataManager: dataManager
            ),
            totalFramesInTargetSequence > minBlendingFrameCount
        else {
            continue
        }

        // --- add the animation if it satisfies all the criteria ---
        if matchingAnimations == nil {
            matchingAnimations = [:]
        }
        matchingAnimations?[animationName] = (startCriticalPoseIndex: startIndex, endCriticalPoseIndex: endIndex)
    }

    return matchingAnimations
}
