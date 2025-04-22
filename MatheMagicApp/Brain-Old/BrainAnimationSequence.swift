//
//  BrainAnimationSequence.swift
import CoreLib

enum buildAnimationSequenceOutcome {
    case tooEarly
    case done
    case failed
}

@MainActor func buildAnimationSequence(
    currentAnimationSequence: inout [AnimationSequenceElement],
    initAnimationSequenceIndex: inout Int,
    moveDirective: MoveDirective,
    customAnimationComponent: inout CustomAnimationComponent,
    dataManager: DataManager
) -> buildAnimationSequenceOutcome {
    var isSuccess: buildAnimationSequenceOutcome = .failed
    // do not transition during custom animations
    // just skip through custom animation here. Further refinement will happen within functions for a specific move type
    guard let transitionableIndex = findNextTransitionableCurrentSequenceIndex(
        currentIndex: initAnimationSequenceIndex,
        animationSequence: currentAnimationSequence
    ) else {
        AppLogger.shared.anim("ERROR: No animation segments after custom animation segments.")
        return .failed
    }
    
    guard transitionableIndex > 0 else {
        AppLogger.shared.anim("🧠 Playing non-transitionable segment. Skipping. Will attempt to transition once in transitionable segment")
        return .tooEarly
    }

    let initAnimationSequenceElement = currentAnimationSequence[transitionableIndex]

    // compare target move type with current move type
    let initMoveType = initAnimationSequenceElement.endPoseName.moveType
    let targetMoveType = moveDirective.moveType

    switch initMoveType {
    case .walk:
        AppLogger.shared.anim("Upcoming move type is walk.")
        switch targetMoveType {
        case .walk:
            if printBrainSystem {
                AppLogger.shared.anim("Target move type is walk.")
            }

            let isSuccess = buildWalkToWalkSequence(
                currentAnimationSequence: &currentAnimationSequence,
                moveDirective: moveDirective,
                dataManager: dataManager
            )

        case .idle:
            AppLogger.shared.anim("Target move type is idle.")
        default:
            AppLogger.shared.error("Error: Unsupported target move type.")
        }

    case .idle:
        AppLogger.shared.anim("Upcoming move type is idle.")
        switch targetMoveType {
        case .walk:
            AppLogger.shared.anim("Target move type is walk.")
            let isUpdatedSequence = buildIdleToWalkSequence(
                currentAnimationSequence: &currentAnimationSequence,
                initAnimationSequenceIndex: transitionableIndex,
                customAnimationComponent: &customAnimationComponent,
                dataManager: dataManager
            )

            if isUpdatedSequence == false {
                AppLogger.shared.error("Error: Failed to build idle to walk sequence. Continue with existing sequence.")
            } else {
                isSuccess = .done
            }

        case .idle:
            AppLogger.shared.anim("Target move type is idle.")
            let isUpdatedSequence = buildIdleToIdleSequence(
                currentAnimationSequence: &currentAnimationSequence,
                initAnimationSequenceIndex: transitionableIndex,
                customAnimationComponent: &customAnimationComponent,
                dataManager: dataManager
            )

            if isUpdatedSequence == false {
                AppLogger.shared.error("Error: Failed to build idle to idle sequence. Continue with existing sequence.")
                // TODO: handle the case of no match found - empty array of segment []. Maybe make it idle till correct event comes along.
            } else {
                isSuccess = .done
            }

        default:
            AppLogger.shared.error("Error: Unsupported target move type.")
        }

    case .transition, .dodge:
        // Have to finish all the consequitive segments in this case for the animation till the critical pose does not belong to this case
        // build sequence from the current animation

        // get the last element
        guard let lastElement = currentAnimationSequence.last,
              let endPoseFrame = lastElement.endPoseFrame
        else {
            AppLogger.shared.error("Error: Sequence is empty. Should run startFresh case. Or more likely no endPoseFrame found for last element.")
            return .failed
        }

        // check if the last element last pose is in mustFinishMoveTypes
        if mustFinishMoveTypes.contains(lastElement.endPoseName.moveType) {
            // pull array of upcoming critical poses
            let criticalPoses = dataManager.getCriticalPoses(
                for: lastElement.animationName,
                startFrameIncl: Int(endPoseFrame),
                endFrameExcl: nil,
                accountForLooping: true
            )

//            if let criticalPoses = criticalPoses {
//                // Find the first pose whose moveType is not in mustFinishMoveTypes
//                if let targetEndPose = criticalPoses.first(where: { !mustFinishMoveTypes.contains($0.poseName.moveType) }) {
//                    let targetEndPoseName = targetEndPose.poseName
//
//                    // extend the sequence till must finish move types are complete
//                    extendSequence(
//                        currentAnimationSequence: &currentAnimationSequence,
//                        targetEndPoseName: targetEndPoseName,
//                        dataManager: dataManager,
//                        isFilledOut: true
//                    )
//                } else {
//                    AppLogger.shared.error("Error: Animation \(lastElement.animationName) has no poses left with moveType not in mustFinishMoveTypes.")
//                    return .failed
//                }
//            } else {
//                AppLogger.shared.error("Error: No critical poses left in animation \(lastElement.animationName).")
//                return .failed
//            }
        }

    case .other:
        AppLogger.shared.error("Error: Undetermined init move type.")
        return .failed
    }

    isSuccess = .done

    return isSuccess
}

// Function to process the animation sequence and return the new index
func findNextTransitionableCurrentSequenceIndex(
    currentIndex: Int?,
    animationSequence: [AnimationSequenceElement]
) -> Int? {
    // Start with the provided index
    var index = currentIndex

    // Loop as long as the index is valid and within bounds
    while let currentIndex = index, currentIndex < animationSequence.count {
        let currentElement = animationSequence[currentIndex]
        let animationName = currentElement.animationName

        // Check if the current animation is a transition and skip this element if so
        if let blendTree = currentElement.blendTree,
           blendTree.isTransition
        {
            index! += 1
        } else {
            if printBrainSystem {
                // if not a transition, safe to use this segment to start a new transition
                AppLogger.shared.anim("Found suitable (i.e. non-transition) segment: \(animationName) with startPose \(currentElement.startPoseName) and endPose \(currentElement.endPoseName) at animationSequence index \(currentIndex). Stopping index advancement.")
            }
            // Exit the loop as the current animation is not a custom transition
            break
        }
    }

    // After processing, check if the index has exceeded the sequence bounds
    if let index = index, index > animationSequence.count - 1 {
        AppLogger.shared.error("Error: Index \(index) is out of bounds. Returning nil.")
        // Set index to nil to indicate no further animations to process
        return nil
    }

    // Return the final index (could be unchanged, advanced, or nil)
    return index
}
