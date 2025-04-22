//
//  2-WhenTransition.swift
//  AnimLib
//
//  Created by Nataliya Kuribko on 3/26/25.
//
import CoreLib

// MARK: - Find Transition Index

// Helper function to prepare the transition index
@MainActor
func findTransitionIndexForCurrentSequence(
    currentAnimationSequence: inout [AnimationSequenceElement],
    moveDirective: MoveDirective,
    dataManager: DataManager
) -> Int? {
    // Pull Sequence Element with initIndex - the one we will be working with, the last element to be played before target transition
    // start critical pose for target = end critical pose of this initAnimationSequenceElement element
    guard let initAnimationSequenceElement = currentAnimationSequence.first else {
        AppLogger.shared.error("Error: No elements in the current animation sequence. We should have at least one element based on the earlier check.")
        return nil
    }
    let initAnimationSequenceIndex = 0

    // Check how animation should change if at all: compare upcoming stride with current stride, change in orientation, etc.
    let startTransitionPoseTypes = getStartTransitionPoseType(moveDirective: moveDirective)

    // Attempt to find the transition index for the current animation starting with the current one

    var initIndex = findTransitionIndexForWalkToWalk(
        currentAnimationSequence: currentAnimationSequence,
        initAnimationSequenceIndex: initAnimationSequenceIndex,
        startTransitionPoseTypes: startTransitionPoseTypes
    )

    // If not found, extend the sequence to the required end pose type and set init index to the last index.
    // if startTransitionPoseTypes is empty then we pass nil (implying that all pose types are valid for transition), otherwise we pass the first element in the array as the target end pose type
    // TODO: For now, this is for looping animations only. For non-looping, extend with default walk via transition.
    if initIndex == nil {
        let targetType: PoseType? = startTransitionPoseTypes.isEmpty ? nil : startTransitionPoseTypes.first
        extendAnimationSequence(
            animationSequence: &currentAnimationSequence,
            isFilledOut: true,
            dataManager: dataManager
        )
        initIndex = currentAnimationSequence.indices.last
    }

    return initIndex
}

/// take an array (startTransitionPoseTypes) and check if it is empty or contains the current pose type. This way, if no restrictions are provided (empty array), any pose type is valid.
private func findTransitionIndexForWalkToWalk(
    currentAnimationSequence: [AnimationSequenceElement],
    initAnimationSequenceIndex: Int,
    startTransitionPoseTypes: [PoseType]
) -> Int? {
    var currentIndex = initAnimationSequenceIndex

    while currentIndex < currentAnimationSequence.count {
        guard let initIndex = findNextTransitionableCurrentSequenceIndex(
            currentIndex: currentIndex,
            animationSequence: currentAnimationSequence
        ) else {
            AppLogger.shared.error("ERROR: No animation segments after custom animation segments.")
            return nil
        }
        currentIndex = initIndex

        let currentPoseName = currentAnimationSequence[currentIndex].endPoseName
        let currentPoseType = currentPoseName.poseType

        // If the array is empty, then all pose types are valid for transition.
        if startTransitionPoseTypes.isEmpty || startTransitionPoseTypes.contains(currentPoseType) {
            AppLogger.shared.anim("Found suitable segment: \(currentPoseName) with endPoseType \(currentPoseType) at animationSequence index \(currentIndex). Stopping index advancement.")
            return currentIndex
        } else if [.high, .low, .toeoff].contains(currentPoseType) {
            currentIndex += 1
        } else {
            AppLogger.shared.error("Error: Unexpected pose type found in the walk-to-walk transition sequence.")
            currentIndex += 1
        }
    }

    return nil
}



func getStartTransitionPoseType(moveDirective: MoveDirective) -> [PoseType] {
    switch walkToWalkIntent {
    case .newWalk:
        return [.high] // Start transition from .high
    case .stride:
        return [.high]
    case .origWalk:
        return [] // any
    case .cirWalk:
        return [] // any
    }
}
