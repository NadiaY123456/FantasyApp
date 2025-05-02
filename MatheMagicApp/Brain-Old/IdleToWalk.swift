////  IdleToWalk.swift
//
//import Foundation
//import CoreLib
//
//func buildIdleToWalkSequence(
//    currentAnimationSequence: inout [AnimationSequenceElement],
//    initAnimationSequenceIndex: Int,
////    eventComponent: inout EventComponent,
//    customAnimationComponent: inout CustomAnimationComponent,
//    dataManager: DataManager
//) -> Bool {
//    // Attempt to find the suitable transition index starting with proposed one
//    guard let initIndex = findTransitionIndexForIdleToWalk(
//        currentAnimationSequence: currentAnimationSequence,
//        initAnimationSequenceIndex: initAnimationSequenceIndex
//    ) else {
//        // If initIndex is nil, exit the function early with false
//        return false
//    }
//
//    // Pull Sequence Element with initIndex - the one we will be working with
//    let initAnimationSequenceElement = currentAnimationSequence[initIndex]
//
//    // pick and build transition animation
//    let newAnimationSequenceElements = pickTransitionAnimationAndCreateSequence(
//        initAnimationSequenceElement: initAnimationSequenceElement,
//        dataManager: dataManager
//    )
//
//    if newAnimationSequenceElements.isEmpty {
//        AppLogger.shared.error("Error: Failed to build new animation sequence for idle to walk transition.")
//        return false // failed to build new animation sequence
//    }
//
//    // include IDs of transition animation segments to complete later
//    let transitionAnimationElementsIDs = newAnimationSequenceElements.map { $0.segmentID }
//    customAnimationComponent.customAnimationSegmentIDsToComplete.append(contentsOf: transitionAnimationElementsIDs.compactMap { $0 })
//
//    // update current animation sequence by appending new animation sequence after initIndex
//    // drop all elements after initAnimationSequenceElement
//    if initIndex < currentAnimationSequence.count {
//        currentAnimationSequence = currentAnimationSequence.dropLast(currentAnimationSequence.count - (initIndex + 1))
//    }
//
//    // append new animation sequence
//    currentAnimationSequence.append(contentsOf: newAnimationSequenceElements)
//
//    return true
//}
//
//// --------------------------
//
//private func findTransitionIndexForIdleToWalk(
//    currentAnimationSequence: [AnimationSequenceElement],
//    initAnimationSequenceIndex: Int
//) -> Int? {
//    var currentIndex = initAnimationSequenceIndex
//
//    while currentIndex < currentAnimationSequence.count {
//        // do not transition during custom animations
//        guard let initIndex = findNextTransitionableCurrentSequenceIndex(
//            currentIndex: currentIndex,
//            animationSequence: currentAnimationSequence
//        ) else {
//            fatalError("ERROR: No animation segments after custom animation segments.")
//        }
//
//        currentIndex = initIndex
//
//        let currentPoseName = currentAnimationSequence[currentIndex].endPoseName
//        let currentPoseType = currentPoseName.poseType
//
//        switch currentPoseType {
//        case .u, .a_q1, .a_q3:
//            // Do not transition when feet are not stable, move to the next pose
//            currentIndex += 1
//
//        default:
//            return currentIndex
//        }
//    }
//
//    // No valid transition found
//    return nil
//}
//
//private func pickTransitionAnimationAndCreateSequence(
//    initAnimationSequenceElement: AnimationSequenceElement,
//    dataManager: DataManager
//) -> [AnimationSequenceElement] {
//    // Determine the target pose name based on foot forward:
//    let targetPoseName: CriticalPoseName
//
//    // simplified version where only foot forward matters:
//    let poseNameStart = initAnimationSequenceElement.startPoseName
//    switch poseNameStart.footForward {
//    case .right:
//        targetPoseName = .idleToWalk_wL_lean_fR_aboutBendKnees
//
//    case .left:
//        targetPoseName = .idleToWalk_wR_lean_fL_aboutBendKnees
//
//    case .both, .none:
//        // Default to right as a fallback or handle differently
//        AppLogger.shared.error("Error: Invalid foot forward \(poseNameStart.footForward) for transition animation. Defaulting to right foot forward.")
//        targetPoseName = .idleToWalk_wL_lean_fR_aboutBendKnees
//    }
//
//    // First, find all animations that have the idle-transition-walk pattern.
//    // We'll define a helper function to detect the subsequence (for not does not impose consequitivity requirement)
//    let candidateAnimations = dataManager.animationDataIndex.values.filter { animDataPoint in
//        hasOrderedSubsequence(
//            source: animDataPoint.moveList,
//            pattern: [.idle, .transition, .walk],
//            isLoop: animDataPoint.isLoop
//        )
//    }
//
//    // Attempt each candidate until we find a suitable sequence
//    for animDataPoint in candidateAnimations {
//        let chosenAnimationName = animDataPoint.animationName
//        let criticalPoses = animDataPoint.criticalPoses
//        let isLooping = animDataPoint.isLoop
//
//        // Find the target pose index
//        guard let targetIndex = criticalPoses.firstIndex(where: { $0.poseName == targetPoseName }) else {
//            // This animation doesn't have the target pose, try next animation
//            continue
//        }
//
//        // Determine the startIndex by moving backwards from the targetIndex
//        // until we find a pose with moveType != .transition.
//        // Handle looping as needed.
//        guard let startIndex = findNonTransitionStartIndex(
//            criticalPoses: criticalPoses,
//            from: targetIndex,
//            isLooping: isLooping
//        ) else {
//            // Could not find a suitable start pose, try next animation
//            continue
//        }
//
//        // Now collect poses from startIndex to the first touched_ground after the target.
//        // Include startIndex, targetIndex (the target pose), and continue until touched_ground.
//        let indicesSequence = gatherSequenceUntilTouchedGround(
//            criticalPoses: criticalPoses,
//            startIndex: startIndex,
//            targetIndex: targetIndex,
//            isLooping: isLooping
//        )
//
//        // If no touched_ground found or indicesSequence is empty, move on
//        guard !indicesSequence.isEmpty else {
//            continue
//        }
//
//        // ---- Now create AnimationSequenceElement array from these indices ---
//
//        // Create customInfo
//        guard let frameStart = initAnimationSequenceElement.endPoseFrame else {
//            AppLogger.shared.error("Error: Failed to get endPoseFrame from initAnimationSequenceElement for the idle to idle transition. Should not happen.")
//            return []
//        }
//
//        // decide on new weight supporting leg - for now just use the current one.
//        var initSide = initAnimationSequenceElement.endPoseName.footOnGround
//
//        if initSide == .none {
//            AppLogger.shared.error("Error: Failed to determine the initial side for the idle to walk transition.")
//            initSide = .left
//        }
//
//        let customInfo = CustomAnimationInfo(
//            animationStart: initAnimationSequenceElement.animationName,
//            frameStart: frameStart,
//            poseNameStart: initAnimationSequenceElement.endPoseName,
//            animationEnd: chosenAnimationName,
//            frameEnd: Float(criticalPoses[indicesSequence.last!].frame),
//            poseNameEnd: criticalPoses[indicesSequence.last!].poseName,
//            side: initSide, // side should match transition animation. InitSide is a placeholder.
//            frequency: nil,
//            //            poseSequence: idleToIdleSequence,
//            recordID: ""
//        )
//        
//        let sequenceElements = createSequenceElements(
//            animationName: chosenAnimationName,
//            criticalPoseIndices: indicesSequence,
//            isFilledOut: false,
//            customAnimationInfo: customInfo,
//            segmentTransitionInput: "idleToWalk",
//            dataManager: dataManager
//        )
//
//        // If we successfully created a sequence
//        if !sequenceElements.isEmpty {
//            return sequenceElements
//        } else {
//            // If failed to create sequence (e.g. no valid pairs), try next animation
//            continue
//        }
//    }
//
//    // If we reach here, no suitable animation found
//    AppLogger.shared.error("Error: No suitable transition animation found.")
//    return []
//}
//
//// Helper function to check if a moveList contains a pattern (like idle -> transition -> walk) in order
///// ! Does not require consecutive elements
//func hasOrderedSubsequence<T: Equatable>(source: [T], pattern: [T], isLoop: Bool) -> Bool {
//    guard !pattern.isEmpty else { return true }
//
//    if !isLoop {
//        // Non-looping: Just do a standard subsequence check
//        var patternIndex = 0
//        for item in source {
//            if item == pattern[patternIndex] {
//                patternIndex += 1
//                if patternIndex == pattern.count {
//                    return true
//                }
//            }
//        }
//        return false
//    } else {
//        // Looping: Consider the array as circular by doubling it
//        let doubledSource = source + source
//        var patternIndex = 0
//        for item in doubledSource {
//            if item == pattern[patternIndex] {
//                patternIndex += 1
//                if patternIndex == pattern.count {
//                    return true
//                }
//            }
//        }
//        return false
//    }
//}
//
//// Gather sequence of pose indices from startIndex through targetIndex until we hit a touched_ground pose.
//private func gatherSequenceUntilTouchedGround(
//    criticalPoses: [CriticalPose],
//    startIndex: Int,
//    targetIndex: Int,
//    isLooping: Bool
//) -> [Int] {
//    var indicesSequence: [Int] = []
//
//    let totalPoses = criticalPoses.count
//    var currentIndex = startIndex
//    var loopedOnce = false
//
//    repeat {
//        indicesSequence.append(currentIndex)
//        let currentPose = criticalPoses[currentIndex].poseName
//
//        // Check if current pose is touched_ground
//        if isTouchedGroundPose(currentPose) {
//            // Found touched_ground, stop
//            break
//        }
//
//        // Move to next index
//        currentIndex += 1
//        if currentIndex >= totalPoses {
//            if isLooping {
//                currentIndex = 0
//                if loopedOnce {
//                    // Avoid infinite loop
//                    break
//                }
//                loopedOnce = true
//            } else {
//                // Non-looping and no touched_ground found till the end
//                // This animation won't work
//                return []
//            }
//        }
//
//        // If we looped back to startIndex, we are stuck in a cycle, break
//        if currentIndex == startIndex {
//            break
//        }
//
//    } while true
//
//    // Check if we ended with touched_ground pose
//    if let lastPoseIndex = indicesSequence.last,
//       isTouchedGroundPose(criticalPoses[lastPoseIndex].poseName)
//    {
//        return indicesSequence
//    } else {
//        // No touched_ground found
//        return []
//    }
//}
//
//// Check if a pose is touched_ground pose by verifying moveType and poseType
//private func isTouchedGroundPose(_ poseName: CriticalPoseName) -> Bool {
//    return poseName.moveType == .walk && poseName.poseType == .low
//}
//
//// Create AnimationSequenceElement array from a sequence of critical pose indices
//func createSequenceElements(
//    animationName: String,
//    criticalPoseIndices: [Int],
//    isFilledOut: Bool,
//    customAnimationInfo: CustomAnimationInfo,
//    segmentTransitionInput: String,
//    customSegmentIDs: [String]? = nil, // Optional array of segment IDs
//    dataManager: DataManager
//) -> [AnimationSequenceElement] {
//    guard let animDataPoint = dataManager.getAnimDataPoint(for: animationName) else {
//        AppLogger.shared.error("Error: Anim data not found for \(animationName)")
//        return []
//    }
//
//    let criticalPoses = animDataPoint.criticalPoses
//    let isLooping = animDataPoint.isLoop
//    let totalFramesInAnimation = (criticalPoses.last?.frame ?? 0) - (criticalPoses.first?.frame ?? 0) + 1
//    var result: [AnimationSequenceElement] = []
//
//    for i in 0 ..< (criticalPoseIndices.count - 1) {
//        let startPose = criticalPoses[criticalPoseIndices[i]]
//        let endPose = criticalPoses[criticalPoseIndices[i + 1]]
//
//        // If looping, avoid segment that goes [endPose, startPose] if identical:
//        // Check if this pair spans over the loop boundary incorrectly.
//        if isLooping {
//            // If next pose frame < current pose frame, it means looping occurred
//            // Normally allowed, but ensure not creating [last pose, first pose] if identical.
//            if endPose.frame < startPose.frame {
//                // This scenario often means we've wrapped around
//                // Check if they are identical poses
//                if startPose.poseName == endPose.poseName {
//                    // Skip this pair
//                    continue
//                }
//            }
//        }
//
//        let frameCount = computeFrameCountBetweenPoses(
//            currentPoseFrame: startPose.frame,
//            nextPoseFrame: endPose.frame,
//            totalFrames: totalFramesInAnimation,
//            isLooping: isLooping
//        )
//
//        // Determine the segment identifier
//        let segmentIdentifier: String
//        if let customIDs = customSegmentIDs, i < customIDs.count {
//            // Use custom segment ID if provided and within bounds
//            segmentIdentifier = customIDs[i]
//        } else {
//            // Fallback to using i+1
//            segmentIdentifier = "\(segmentTransitionInput)__\(i + 1)__\(UUID().uuidString)"
//        }
//
//        let elem = AnimationSequenceElement(
//            animationName: animationName,
//            startPoseName: startPose.poseName,
//            startPoseFrame: Float(startPose.frame),
//            startPoseID: startPose.poseID,
//            endPoseName: endPose.poseName,
//            endPoseFrame: Float(endPose.frame),
//            endPoseID: endPose.poseID,
//            frameCount: frameCount,
//            currentFrame: nil,
//            isPlaying: false,
//            speed: 1,
//            segmentID: segmentIdentifier,
//            animData: nil,
//            customAnimationInfo: customAnimationInfo,
//            customAnimationSegment: nil,
//            blendInfo: nil,
//            blendTree: nil,
//            isFilledOut: isFilledOut
//        )
//        result.append(elem)
//    }
//
//    return result
//}
//
///// Finds the first pose index going backwards from `fromIndex` (excluding `fromIndex` itself)
///// that has a moveType != .transition. If none is found before reaching the start and `isLooping` is true,
///// it continues from the end. If still none found, returns nil.
//private func findNonTransitionStartIndex(
//    criticalPoses: [CriticalPose],
//    from fromIndex: Int,
//    isLooping: Bool
//) -> Int? {
//    let totalPoses = criticalPoses.count
//    guard totalPoses > 1 else {
//        return nil // Not enough poses to find a non-transition one before the target
//    }
//
//    // We'll start searching just before the targetIndex
//    var currentIndex = fromIndex - 1
//    var loopedOnce = false
//
//    while currentIndex != fromIndex {
//        let pose = criticalPoses[currentIndex].poseName //TODO: FIX! currentIndex = -1 when fromIndex = 0
//        if pose.moveType != .transition {
//            return currentIndex
//        }
//
//        currentIndex -= 1
//        if currentIndex < 0 {
//            if isLooping {
//                // Wrap around
//                currentIndex = totalPoses - 1 - 1 // additional -1 because first and last poses are identical
//                if loopedOnce {
//                    // We've already looped once, no point continuing indefinitely
//                    break
//                }
//                loopedOnce = true
//            } else {
//                // Non-looping: no more poses before fromIndex
//                break
//            }
//        }
//    }
//
//    // No suitable pose found
//    return nil
//}
