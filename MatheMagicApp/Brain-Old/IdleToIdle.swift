//  IdleToIdle.swift

import Foundation
import simd
import CoreLib

@MainActor func buildIdleToIdleSequence(
    currentAnimationSequence: inout [AnimationSequenceElement],
    initAnimationSequenceIndex: Int,
//    eventComponent: inout EventComponent,
    customAnimationComponent: inout CustomAnimationComponent,
    dataManager: DataManager
) -> Bool {
    // Attempt to find the transition index starting with proposed one
    guard let initIndex = findTransitionIndexForIdleToIdle(
        currentAnimationSequence: currentAnimationSequence,
        initAnimationSequenceIndex: initAnimationSequenceIndex
    ) else {
        // If initIndex is nil, exit the function early with false
        return false
    }
        
    // Pull Sequence Element with initIndex - the one we will be working with
    let initAnimationSequenceElement = currentAnimationSequence[initIndex]
    
    // decide on new weight supporting leg
    let initSide = idleToIdleDecideInitSide(initAnimationSequenceElement: initAnimationSequenceElement)
    AppLogger.shared.debug("DEBUG: initSide: \(initSide)")
    
    if initSide == .none {
        AppLogger.shared.error("Error: Failed to determine the initial side for the idle to idle transition. Should not happen.")
        return false
    }
    
    // determine target animations
    let targetAnimations = idleToIdleTargetAnimations(
        initSide: initSide,
        initAnimationSequenceElement: initAnimationSequenceElement,
//        eventComponent: &eventComponent,
        dataManager: dataManager
    )
    
    guard !targetAnimations.isEmpty else {
        AppLogger.shared.error("Error: No target animations found for the current event and settings. Need to reconsider the event or move type")
        return false // failed to build new animation sequence
    }
    
    // build animation sequence
    guard let newAnimationSequenceElements = brainAnimationSequenceForIdleToIdle(
        initAnimationSequenceElement: initAnimationSequenceElement,
        initSide: initSide,
        targetAnimations: targetAnimations,
        customAnimationComponent: &customAnimationComponent,
        dataManager: dataManager
    ) else {
        AppLogger.shared.error("Error: Failed to build new animation sequence for idle to idle transition.")
        return false // failed to build new animation sequence
    }
    
    AppLogger.shared.debug("DEBUG: transition plus end animation elements count: \(newAnimationSequenceElements.count)")
    
    // update current animation sequence by appending new animation sequence after initIndex
    // drop all elements after initAnimationSequenceElement
    if initIndex < currentAnimationSequence.count {
        currentAnimationSequence = currentAnimationSequence.dropLast(currentAnimationSequence.count - (initIndex + 1))
    }
    
    // append new animation sequence
    currentAnimationSequence.append(contentsOf: newAnimationSequenceElements)

    return true
}

@MainActor private func brainAnimationSequenceForIdleToIdle(
    initAnimationSequenceElement: AnimationSequenceElement,
    initSide: Side,
    targetAnimations: [String: [Int]],
    customAnimationComponent: inout CustomAnimationComponent,
    dataManager: DataManager
) -> [AnimationSequenceElement]? {
    var newAnimationSequence: [AnimationSequenceElement] = []
    
    for targetAnimation in targetAnimations.keys {
        // TODO: first animation is a random choice. Sort animations in priority order.

        // Get the data. Move to the next target animation in the list if not found.
        guard let animDataPointTarget = dataManager.getAnimDataPoint(for: targetAnimation) else {
            AppLogger.shared.anim("Target animation '\(targetAnimation)' is not found in the animDataSet. Moving to the next target animation.")
            continue
        }
        
        // reset the animation sequence
        newAnimationSequence = []
        
        // TODO: determine if transition is needed: do not need only if critical poseIDs are matching
        
        //  === create Full Idle-To-Idle set of segments ===

        // populate custom animation info
        
        // take the first critical pose index in the animation (the top choice)
        let targetAnimationCriticalPoseIndex = targetAnimations[targetAnimation]![0]
        let targetCriticalPose = animDataPointTarget.criticalPoses[targetAnimationCriticalPoseIndex]
        
        guard let frameStart = initAnimationSequenceElement.endPoseFrame else {
            AppLogger.shared.error("Error: Failed to get endPoseFrame from initAnimationSequenceElement for the idle to idle transition. Should not happen.")
            return nil
        }
        
        AppLogger.shared.debug("DEBUG: Creating custom animation info for idle to idle transition: start animation '\(initAnimationSequenceElement.animationName)', start pose '\(initAnimationSequenceElement.endPoseName)', end animation '\(targetAnimation)', end pose '\(targetCriticalPose.poseName)")
        
        let customInfo = CustomAnimationInfo(
            animationStart: initAnimationSequenceElement.animationName,
            frameStart: frameStart,
            poseNameStart: initAnimationSequenceElement.endPoseName,
            animationEnd: targetAnimation,
            frameEnd: Float(targetCriticalPose.frame),
            poseNameEnd: targetCriticalPose.poseName,
            side: initSide,
            frequency: nil,
            recordID: "1" // TODO: hardcoded
        )
        
        // pick and build transition animation
        guard let transitionSequenceElements = pickTransitionAnimationAndCreateSequence(
            initAnimationSequenceElement: initAnimationSequenceElement,
            customInfo: customInfo,
            dataManager: dataManager
        ) else {
            AppLogger.shared.error("Error: Failed to build new animation sequence for idle to idle transition.")
            return nil // failed to build new animation sequence
        }
        
        // append transition animation to the new animation sequence
        newAnimationSequence.append(contentsOf: transitionSequenceElements)
        
        // include IDs of transition animation segments to complete later
        let transitionAnimationElementsIDs = transitionSequenceElements.map { $0.segmentID }
        customAnimationComponent.customAnimationSegmentIDsToComplete.append(contentsOf: transitionAnimationElementsIDs.compactMap { $0 })
        
//        // add segments with target animation playing
//        let targetAnimationSubSequence = constructAnimationSequence(
//            from: animDataPointTarget,
//            startCriticalPoseIndex: targetAnimationCriticalPoseIndex,
//            endCriticalPoseIndex: animDataPointTarget.criticalPoses.count - 1
//        )
//        newAnimationSequence.append(contentsOf: targetAnimationSubSequence)
        
        if newAnimationSequence.count > 0 {
            AppLogger.shared.debug("DEBUG: segment IDs to complete: \(customAnimationComponent.customAnimationSegmentIDsToComplete)")
            AppLogger.shared.debug("DEBUG: new animation sequence count: \(newAnimationSequence.count)")
            break
        }
    }
    return newAnimationSequence
}

/// ** Determine tartget animations array **
private func idleToIdleTargetAnimations(
    initSide: Side,
    initAnimationSequenceElement: AnimationSequenceElement,
//    eventComponent: inout EventComponent,
    dataManager: DataManager
) -> [String: [Int]] {
    AppLogger.shared.anim("TEST: building idle to idle target animations")
    
    // determine appropriate critical poses
    let targetPoseNames = findSuitableCriticalPosesTargetAnimation(initSide: initSide)
    
    if targetPoseNames.isEmpty {
        AppLogger.shared.error("Error: No suitable critical poses found for the idle to idle transition. Should not happen.")
        return [:]
    }
    
    // find animations with matching critical poses within idle animations
    let matchingAnimations = dataManager.findAnimationsWithCriticalPoses(withMoveTypes: [.idle], criticalPoseNames: targetPoseNames)
    
//    if !matchingAnimations.isEmpty {
//        // clear new events since found matching animations
//        MarkAllEventsOld(for: &eventComponent)
//    }
    
    return matchingAnimations
}

private func findTransitionIndexForIdleToIdle(
    currentAnimationSequence: [AnimationSequenceElement],
    initAnimationSequenceIndex: Int
) -> Int? {
    var currentIndex = initAnimationSequenceIndex
        
    while currentIndex < currentAnimationSequence.count {
        // do not transition during custom animations
        guard let initIndex = findNextTransitionableCurrentSequenceIndex(
            currentIndex: currentIndex,
            animationSequence: currentAnimationSequence
        ) else {
            fatalError("ERROR: No animation segments after custom animation segments.")
        }
        
        currentIndex = initIndex
        
        let currentPoseName = currentAnimationSequence[currentIndex].endPoseName
        let currentPoseType = currentPoseName.poseType
            
        switch currentPoseType {
        case .neutral_to_wlean, .wlean_to_lean:
            // Transition found
            return currentIndex
                
        case .u:
            // Do not transition, move to the next pose
            currentIndex += 1
                
        case .wlift_to_lift, .a_q3:
            // do not transition FOR NOW, wait for next pose //TODO: develop transition logic
            currentIndex += 1
            
        case .lean_to_wlift:
            currentIndex += 1
                                                        
        case .a_q1:
            // do not transition FOR NOW, wait for pose q3 //TODO: develop transition logic
            currentIndex += 1
                
        default:
            // Handle unexpected pose types if necessary
            AppLogger.shared.error("Error: Unexpected pose type found in the idle to idle transition sequence.")
            currentIndex += 1
        }
    }
        
    // No valid transition found
    return nil
}

private func idleToIdleDecideInitSide(
    initAnimationSequenceElement: AnimationSequenceElement
) -> Side {
    let initPoseName = initAnimationSequenceElement.endPoseName
    let side = initPoseName.sideOnGround
    
    return side
}

private func findSuitableCriticalPosesTargetAnimation(initSide: Side) -> [CriticalPoseName] {
    var targetPoses: [CriticalPoseName] = []

    if initSide == .right {
        targetPoses = [.wL_neutral_to_wlean, .wL_wlean_to_lean]
    } else if initSide == .left {
        targetPoses = [.wR_neutral_to_wlean, .wR_wlean_to_lean]
    } else {
        targetPoses = []
    }
    
    return targetPoses
}

@MainActor private func pickTransitionAnimationAndCreateSequence(
    initAnimationSequenceElement: AnimationSequenceElement,
    customInfo: CustomAnimationInfo,
    dataManager: DataManager
) -> [AnimationSequenceElement]? {
    let startAnimationName = customInfo.animationStart
    let frameStart = customInfo.frameStart
    let endAnimationName = customInfo.animationEnd
    let frameEnd = customInfo.frameEnd
    
    // 1) get foot positions for START
    guard let (leftFootLocationStart, rightFootLocationStart) = pullFeetLocation(
        animationName: startAnimationName,
        frame: Int(frameStart),
        dataManager: dataManager
    ) else {
        AppLogger.shared.error("Error: Could not pull start foot locations for \(startAnimationName) at frame \(frameStart)")
        return nil
    }

    // 2) get foot positions for END
    guard let (leftFootLocationEnd, rightFootLocationEnd) = pullFeetLocation(
        animationName: endAnimationName,
        frame: Int(frameEnd),
        dataManager: dataManager
    ) else {
        AppLogger.shared.error("Error: Could not pull end foot locations for \(endAnimationName) at frame \(frameEnd)")
        return nil
    }

    // Helper to compute the foot vector: right - left
    func normalizedFootVector(leftFoot: SIMD3<Float>, rightFoot: SIMD3<Float>) -> SIMD3<Float> {
        return rightFoot - leftFoot
    }
    
    let startFootVector = normalizedFootVector(
        leftFoot: leftFootLocationStart,
        rightFoot: rightFootLocationStart
    )
    let endFootVector = normalizedFootVector(
        leftFoot: leftFootLocationEnd,
        rightFoot: rightFootLocationEnd
    )
    
    // 3) Gather all idleToIdle transitions
    guard let idleToIdleTransitions = transitionSequencesDict[.idleToIdle],
          !idleToIdleTransitions.isEmpty
    else {
        AppLogger.shared.error("Error: No idleToIdle transitions found in transitionSequencesDict.")
        return nil
    }
    
    // 4) Among these transitions, pick the best match for feet positions
    var bestTransition: TransitionSequence?
    var bestScore: Float = .greatestFiniteMagnitude
    
    for transition in idleToIdleTransitions {
        let tStart = transition.feetGlobalTransformStart
        let tEnd = transition.feetGlobalTransformEnd
        
        let transitionStartVector = normalizedFootVector(
            leftFoot: tStart.leftFootTransform.translation,
            rightFoot: tStart.rightFootTransform.translation
        )
        let transitionEndVector = normalizedFootVector(
            leftFoot: tEnd.leftFootTransform.translation,
            rightFoot: tEnd.rightFootTransform.translation
        )
        
        let footDeltaStart = distance(transitionStartVector, startFootVector)
        let footDeltaEnd = distance(transitionEndVector, endFootVector)
        let score = footDeltaStart * footDeltaStart + footDeltaEnd * footDeltaEnd
        
        if score < bestScore {
            bestScore = score
            bestTransition = transition
        }
        
        AppLogger.shared.debug("DEBUG: Transition \(transition.animationName): footDeltaStart: \(footDeltaStart), footDeltaEnd: \(footDeltaEnd), score: \(score)")
    }
    
    guard let chosenTransition = bestTransition else {
        AppLogger.shared.error("Error: Could not find a suitable idleToIdle transition.")
        return nil
    }
    
    
    // 5) Retrieve the chosen animation
    let transitionAnimation = chosenTransition.animationName
    guard let animDataPoint = dataManager.getAnimDataPoint(for: transitionAnimation) else {
        AppLogger.shared.error("Error: No animDataPoint found for animation: \(transitionAnimation)")
        return nil
    }
    
    // Sort poses by `order` so we respect the intended sequence
    let sortedTransitionPoses = chosenTransition.transitionPoses.sorted { $0.order < $1.order }
    // print frames of sortedTransitionPoses array , which is sortedTransitionPoses[i].frame:
    AppLogger.shared.debug("DEBUG: sortedTransitionPoses frames: \(sortedTransitionPoses.map(\.frame))")
    
    // 6) Convert frames => criticalPose indices
    var criticalPoseIndices: [Int] = []
    for pose in sortedTransitionPoses {
        // We assume each .frame is an actual frame in animDataPoint.criticalPoses
        if let idx = animDataPoint.criticalPoses.firstIndex(where: { $0.frame == pose.frame }) {
            criticalPoseIndices.append(idx)
        }
    }
    
    guard !criticalPoseIndices.isEmpty else {
        AppLogger.shared.error("Error: No valid critical pose indices found for chosen animation: \(transitionAnimation)")
        return nil
    }
    
    guard criticalPoseIndices.count > 1 else {
        AppLogger.shared.anim("Not enough critical poses to form a transition for animation: \(transitionAnimation)")
        return nil
    }
    
    // 7) Build customSegmentIDs that encode transition animation location in transitionSequencesDict
    
    // get index in the dictionary
    guard let chosenTransitionIndex = idleToIdleTransitions.firstIndex(where: {
        $0.sequenceID == chosenTransition.sequenceID
    }) else {
        AppLogger.shared.error("Error: Could not find the chosen transition in transitionSequencesDict.")
        return nil
    }
    let sequenceID =  String(UUID().uuidString.prefix(5))
    let transitionType = chosenTransition.transitionType
    let transitionName = chosenTransition.animationName
    // When iterating over sortedTransitionPoses:
    let customSegmentIDs: [String] = sortedTransitionPoses.map { pose in
        // Format: "<transitionType>_<sequenceIndex>_<order>_<criticalPoseName>"
        let encoded = "\(transitionType)__\(chosenTransitionIndex)__\(pose.order)__\(transitionName)__\(sequenceID)"
        return encoded
    }

    // 8) Create the sequence
    let sequence = createSequenceElements(
        animationName: transitionAnimation,
        criticalPoseIndices: criticalPoseIndices,
        isFilledOut: false,
        customAnimationInfo: customInfo,
        segmentTransitionInput: "idleToIdle",
        customSegmentIDs: customSegmentIDs,
        dataManager: dataManager
    )
    
    guard !sequence.isEmpty else {
        AppLogger.shared.error("Error: Failed to create sequence elements for animation: \(transitionAnimation)")
        return nil
    }
    
    return sequence
}




/// Retrieves the left and right foot locations from an animation at a specific frame.
/// - Parameters:
///   - animationName: The name of the animation.
///   - frame: The frame number of interest.
///   - dataManager: The `DataManager` containing AnimDataPoint info.
/// - Returns: A tuple `(leftFoot, rightFoot)` containing the foot positions. Returns nil if unavailable.
private func pullFeetLocation(
    animationName: String,
    frame: Int,
    dataManager: DataManager
) -> (leftFoot: SIMD3<Float>, rightFoot: SIMD3<Float>)? {
    // Get the corresponding AnimDataPoint
    guard let animDataPoint = dataManager.getAnimDataPoint(for: animationName) else {
        AppLogger.shared.anim("pullFeetLocation Error: No animDataPoint found for \(animationName)")
        return nil
    }
    
    // Retrieve the critical pose that matches the given frame
    let criticalPoses = animDataPoint.criticalPoses.elements(inFrameRange: frame, to: frame)
    guard let globalTransforms = criticalPoses.first?.globalTransform else {
        AppLogger.shared.anim("pullFeetLocation Error: No criticalPose/globalTransforms found for \(animationName) at frame \(frame)")
        return nil
    }
    
    // Find the left foot
    let leftFootLocation = globalTransforms
        .first(where: { $0.key.hasSuffix("L_Foot") })?
        .value.location ?? SIMD3<Float>(0, 0, 0)
    
    // Find the right foot
    let rightFootLocation = globalTransforms
        .first(where: { $0.key.hasSuffix("R_Foot") })?
        .value.location ?? SIMD3<Float>(0, 0, 0)
    
    return (leftFootLocation, rightFootLocation)
}
