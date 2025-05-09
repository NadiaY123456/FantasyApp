////  WalkToWalk.swift
//
//import CoreLib
//import Foundation
//
//@MainActor func buildWalkToWalkSequence(
//    currentAnimationSequence: inout [AnimationSequenceElement],
//    moveDirective: MoveDirective,
//    dataManager: DataManager
//) -> buildAnimationSequenceOutcome {
//        
//    // determine the index when this transition can happen.
//     guard let initIndex = findTransitionIndexForCurrentSequence(
//        currentAnimationSequence: &currentAnimationSequence,
//        moveDirective: moveDirective, //Error: Cannot convert value of type '[WalkToWalkIntent].Type' to expected argument type '[WalkToWalkIntent]'
//        dataManager: dataManager
//    ) else {
//        AppLogger.shared.error("Error: No transition index found for walk to walk transition.")
//         return .failed
//    }
//    
//    // Don't do anything till reach that moment because other events can overule this one.
//    if initIndex > 0 {
//        if printBrainSystem {
//            AppLogger.shared.anim("Too early to construct walk to walk transition. The transitionable segment is at index \(initIndex) of animation sequence.")
//        }
//        return .tooEarly
//    } else if let currentFrame = currentAnimationSequence[initIndex].currentFrame,
//              let endPoseFrame = currentAnimationSequence[initIndex].endPoseFrame,
//              (endPoseFrame - currentFrame) > 5 { // Start doing it only tin the last 5 frames
//        if printBrainSystem {
//            AppLogger.shared.anim("Too early to construct walk to walk transition. The transitionable segment is not yet close to the end.")
//        }
//        return .tooEarly
//    }
//    
//    
//    // MARK: select target animations
//    
//    let initAnimationSequenceElement = currentAnimationSequence[initIndex]
//
//    let targetAnimations = walkToWalkTargetAnimations(
//        initAnimationSequenceElement: initAnimationSequenceElement,
//        walkToWalkIntents: walkToWalkIntents,
//        dataManager: dataManager
//    )
//
//    // --- DEBUG:
//    //    // exclude current animation from targetAnimations
//    //    targetAnimations.removeAll { $0 == initAnimationSequenceElement.animationName }
//    // keep only current animation in targetAnimations
//    //    targetAnimations.removeAll { $0 != initAnimationSequenceElement.animationName }
//    // --- end DEBUG
//
//    guard !targetAnimations.isEmpty else {
//        AppLogger.shared.error("Error: No target animations found for the current event and settings. Need to reconsider the event or move type")
//        return .failed // failed to build new animation sequence
//    }
//    
//    // MARK: construct the target sequence
//    
//    // --- construct raw sequence without any transitions or modifications, just based on orig animations (loaded from json)
//    guard let rawTargetSequence = constructRawTargetSequence(
//        targetAnimations: targetAnimations,
//        dataManager: dataManager
//    ) else {
//        AppLogger.shared.error("🧠 Error: Failed to construct raw target sequence for any of the target animations.")
//        return .failed // failed to build new animation sequence
//    }
//    
//    // introduce modifications
//    
//    
//    
//    
//
//    // decide on the path required: direct connection, inertialization or blend in
//    let connectionPath = transitionType.connectionPath
//
//    switch connectionPath {
//    case .connectingPose:
//
//        let isSuccess = buildConnectionPoseSequence(
//            animationSequence: &currentAnimationSequence,
//            initIndex: initIndex,
//            transitionType: transitionType,
//            dataManager: dataManager
//        )
//        return isSuccess
//
//    case .inertialization:
//        break
//
//    // MARK: blend-in path
//
//    case .blendIn:
//        // build target animation sequence portion that blends in with initial animation
//        let targetBlendInSequence = buildTargetSequenceToBlendIn(
//            targetAnimations: targetAnimations,
//            dataManager: dataManager
//        )
//
//        guard let targetBlendInSequenceElementLast = targetBlendInSequence.last else {
//            return false // failed to build new animation sequence
//        }
//
//        // build initial animation sequence portion that will blend
//        extendSequence(
//            currentAnimationSequence: &currentAnimationSequence,
//            transitionType: transitionType,
//            targetEndPoseName: targetBlendInSequenceElementLast.endPoseName,
//            dataManager: dataManager,
//            isFilledOut: false
//        )
//
//        // replace currentAnimationSequence starting from initIndex + 1 with targetBlendInSequence elements, and move currentAnimationSequence element into blendTree info
//        blendInTargetSequenceAndAttach(
//            currentAnimationSequence: &currentAnimationSequence,
//            targetBlendInSequence: targetBlendInSequence,
//            initIndex: initIndex
//        )
//
//        // Extend the target animation sequence from the last blended pose to the end of the animation
//        extendAnimationSequence(
//            animationSequence: &currentAnimationSequence,
//            fromElement: targetBlendInSequenceElementLast,
//            dataManager: dataManager
//        )
//    }
//
//    return true
//}
//
//
//
//
//
//// MARK: - Sequence Operations
//
//private func buildTargetSequenceToBlendIn(
//    targetAnimations: [String: (endCriticalPoseName: CriticalPoseName, totalFrames: Float, indexPairs: [[Int]])],
//    dataManager: DataManager
//) -> [AnimationSequenceElement] {
//    var targetAnimationSequence: [AnimationSequenceElement] = []
//
//    // We only need one target animation completed, so we'll use the first one in the dictionary
//    for (targetAnimation, targetAnimationData) in targetAnimations {
//        // Get the animation data for the target animation
//        guard let animDataPointTarget = dataManager.getAnimDataPoint(for: targetAnimation) else {
//            AppLogger.shared.anim("Target animation '\(targetAnimation)' is not found in the animDataSet. Moving to the next target animation.")
//            continue
//        }
//
//        let criticalPoses = animDataPointTarget.criticalPoses
//        let isLooping = animDataPointTarget.isLoop
//        let totalFramesInAnimation = (criticalPoses.last?.frame ?? 0) - (criticalPoses.first?.frame ?? 0) + 1
//
//        // Iterate over the indicesSequence to create AnimationSequenceElements
//        for pair in targetAnimationData.indexPairs {
//            let index = pair[0]
//            let nextIndex = pair[1]
//            let currentPose = criticalPoses[index]
//            let nextPose = criticalPoses[nextIndex]
//
//            // Calculate frameCount for the segment
//            let frameCount = computeFrameCountBetweenPoses(
//                currentPoseFrame: currentPose.frame,
//                nextPoseFrame: nextPose.frame,
//                totalFrames: totalFramesInAnimation,
//                isLooping: isLooping
//            )
//
//            let duration = Double(frameCount - 1) / Double(frameRate)
//
//            // Create AnimationSequenceElement
//            let animationSequenceElement = AnimationSequenceElement(
//                animationName: targetAnimation,
//                startPoseName: currentPose.poseName,
//                startPoseFrame: Float(currentPose.frame),
//                startPoseID: currentPose.poseID,
//                endPoseName: nextPose.poseName,
//                endPoseFrame: Float(nextPose.frame),
//                endPoseID: nextPose.poseID,
//                frameCount: frameCount,
//                currentFrame: nil,
//                isPlaying: false,
//                speed: 1.0,
//                segmentID: UUID().uuidString,
//                animData: nil,
//                customAnimationInfo: nil,
//                customAnimationSegment: nil,
//                blendInfo: BlendInfo(
//                    ownBlendWeightType: .increasing,
//                    otherBlendWeightType: .decreasing,
//                    isAdditive: false,
//                    blendFunction: .crossFade,
//                    blendType: .sCurve,
//                    fromEffectiveSeriesDuration: 0,
//                    toEffectiveSeriesDuration: duration,
//                    totalEffectiveSeriesDuration: duration
//                ),
//                blendTree: nil,
//                isFilledOut: false
//            )
//
//            // Append the element to the targetAnimationSequence
//            targetAnimationSequence.append(animationSequenceElement)
//        }
//
//        // Successfully created AnimationSequenceElements for one target animation, exit the loop
//        break
//    }
//
//    return targetAnimationSequence
//}
//
//func blendInTargetSequenceAndAttach(
//    currentAnimationSequence: inout [AnimationSequenceElement],
//    targetBlendInSequence: [AnimationSequenceElement],
//    initIndex: Int
//) {
//    // 1. take initIndex + 1 in currentAnimationSequence starting .
//    // 2. take one element from targetBlendInSequence with index 0
//    // 3. check that their startPoseNames and endPoseNames match. If not, error
//    // 4. construct blendTree for the currentAnimationSequence using the targetBlendInSequence element.
//    // 5. Mark currentAnimationSequence [initIndex + 1]. isFilledOut = true
//    // 6. repeat for next elements in currentAnimationSequence and targetBlendInSequence until run out of elements in targetBlendInSequence.
//
//    // effective duration for currentElement and targetElement should match. Do so by adjusting speeds.
//    // Gradually change speed so that currentElement.speed = 1 for i = 0 and targetElement.speed = 1 for i = targetBlendInSequence.count - 1
//
//    // Start from initIndex + 1 in currentAnimationSequence
//    var currentIndex = initIndex + 1
//
//    // Ensure the starting index is within bounds
//    guard currentIndex < currentAnimationSequence.count else {
//        AppLogger.shared.error("Error: initIndex + 1 is out of bounds in currentAnimationSequence.")
//        return
//    }
//
//    var fromEffectiveDuration: Float = 0 // Initialize cumulative duration
//    let totalBlendSteps = targetBlendInSequence.count
//
//    /// Calculate the required count of elements in currentAnimationSequence
//    let requiredCount = initIndex + totalBlendSteps + 1
//
//    // Ensure there are enough elements in currentAnimationSequence
//    guard currentAnimationSequence.count >= requiredCount else {
//        AppLogger.shared.error("Error: Not enough elements in currentAnimationSequence to attach the blend-in sequence.")
//        return
//    }
//
//    // Remove elements in currentAnimationSequence that are beyond the required count
//    if currentAnimationSequence.count > requiredCount {
//        currentAnimationSequence.removeSubrange(requiredCount..<currentAnimationSequence.count)
//    }
//
//    // Iterate over targetBlendInSequence
//    for i in 0..<targetBlendInSequence.count {
//        var targetElement = targetBlendInSequence[i]
//
//        var currentElement = currentAnimationSequence[currentIndex]
//
//        // Check if startPoseNames and endPoseNames match
//        if currentElement.startPoseName != targetElement.startPoseName ||
//            currentElement.endPoseName != targetElement.endPoseName
//        {
//            AppLogger.shared.error("Error: startPoseNames and endPoseNames do not match at index \(currentIndex) across base and blend animations: Start Poses for current and target: \(currentElement.startPoseName) and \(targetElement.startPoseName), End Poses for current and target: \(currentElement.endPoseName) and \(targetElement.endPoseName). ")
//            return
//        }
//
//        // Construct blendTree for currentElement using targetElement
//        guard let currentFrameCount = currentElement.frameCount,
//              let targetFrameCount = targetElement.frameCount
//        else {
//            AppLogger.shared.error("Error: frameCount is nil for targetElement at index \(i).")
//            return
//        }
//
//        // --- Effective duration and speeds
//        let targetWeight = totalBlendSteps > 1 ? Float(i) / Float(totalBlendSteps - 1) : 0.5
////        let targetWeight = Float(0) // DEBUG
//
//        let effectiveDuration = targetWeight * Float(targetFrameCount) / frameRate + (1 - targetWeight) * Float(currentFrameCount) / frameRate
//
//        // Adjust speeds so that durations match effectiveDuration
//        targetElement.speed = effectiveDuration * frameRate / Float(targetFrameCount)
//        currentElement.speed = effectiveDuration * frameRate / Float(currentFrameCount)
//
//        // Update fromEffectiveDuration and toEffectiveDuration
//        let toEffectiveDuration = fromEffectiveDuration + effectiveDuration
//
//        // --- blendInfo for current element
//        let blendInfo = BlendInfo(
//            // start animation, blend weight is 1 at the beginning
//            ownBlendWeightType: .decreasing,
//            otherBlendWeightType: .increasing,
//            isAdditive: false,
//            blendFunction: .crossFade,
//            blendType: .sCurve,
//            fromEffectiveSeriesDuration: Double(fromEffectiveDuration),
//            toEffectiveSeriesDuration: Double(toEffectiveDuration),
//            totalEffectiveSeriesDuration: -1 // filled out later in the function
//        )
//        currentElement.blendInfo = blendInfo
//
//        // --- mark as filled out
//        currentElement.isFilledOut = true
//        targetElement.isFilledOut = true
//
//        // Create blendTree in targetElement, using currentElement as the source
//        let blendTree = BlendTree(
//            sourceElements: [currentElement],
//            isTransition: true
//        )
//        targetElement.blendTree = blendTree
//
//        // Replace currentElement with targetElement in the sequence
//        currentAnimationSequence[currentIndex] = targetElement
//
//        // Update fromEffectiveDuration for next iteration
//        fromEffectiveDuration = toEffectiveDuration
//
//        // Move to the next index in currentAnimationSequence
//        currentIndex += 1
//    }
//
//    for i in initIndex + 1..<requiredCount {
//        // Safely unwrap blendTree
//        guard var blendTree = currentAnimationSequence[i].blendTree else {
//            AppLogger.shared.error("Error: blendTree is nil at index \(i).")
//            continue
//        }
//
//        // Ensure sourceElements has at least one element
//        guard !blendTree.sourceElements.isEmpty else {
//            AppLogger.shared.error("Error: sourceElements is empty at index \(i).")
//            continue
//        }
//
//        // Safely unwrap blendInfo of the first source element
//        guard var blendInfo = blendTree.sourceElements[0].blendInfo else {
//            AppLogger.shared.error("Error: blendInfo is nil for sourceElements[0] at index \(i).")
//            continue
//        }
//
//        // Perform the assignment
//        blendInfo.totalEffectiveSeriesDuration = Double(fromEffectiveDuration)
//
//        // Assign the modified blendInfo back to the source element
//        blendTree.sourceElements[0].blendInfo = blendInfo
//
//        // Assign the modified blendTree back to the currentAnimationSequence
//        currentAnimationSequence[i].blendTree = blendTree
//    }
//}
//
//@MainActor func extendSequenceForLooping(
//    currentAnimationSequence: inout [AnimationSequenceElement],
//    targetEndPoseType: PoseType? = nil, // Now optional
//    targetEndPoseName: CriticalPoseName? = nil, // optional. need to enter one of the optionals
//    dataManager: DataManager,
//    isFilledOut: Bool
//) {
//    // Extract necessary information
//    guard let animationName = currentAnimationSequence.last?.animationName,
//          let startPoseName = currentAnimationSequence.last?.endPoseName,
//          let endPoseFrame = currentAnimationSequence.last?.endPoseFrame
//    else {
//        AppLogger.shared.error("Error: Missing data in currentAnimationSequence.")
//        return
//    }
//
//    // Determine targetEndPoseName
//    let resolvedTargetEndPoseName: CriticalPoseName
//
//    if let providedTargetEndPoseName = targetEndPoseName {
//        resolvedTargetEndPoseName = providedTargetEndPoseName
//    } else if let endPoseType = targetEndPoseType {
//        guard let computedTargetEndPoseName = findNextPoseName(
//            startPoseName: startPoseName,
//            endPoseType: endPoseType,
//            poseSequence: walkPoseSequence,
//            accountForLooping: true
//        ) else {
//            AppLogger.shared.error("Error: No target end pose name found.")
//            return
//        }
//        resolvedTargetEndPoseName = computedTargetEndPoseName
//    } else {
//        AppLogger.shared.error("Error: Neither targetEndPoseType nor targetEndPoseName provided.")
//        return
//    }
//
//    // Get animation data
//    guard let animDataPoint = dataManager.getAnimDataPoint(for: animationName) else {
//        AppLogger.shared.error("Error: Animation data not found for \(animationName)")
//        return
//    }
//
//    let criticalPoses = animDataPoint.criticalPoses
//    let isLooping = animDataPoint.isLoop
//    let totalFramesInAnimation = (criticalPoses.last?.frame ?? 0) - (criticalPoses.first?.frame ?? 0) + 1
//
//    // Use helper function to find indices sequence
//    guard let result = findIndicesBetweenCriticalPoses(
//        criticalPoses: criticalPoses,
//        startPoseName: startPoseName,
//        startPoseFrame: endPoseFrame,
//        targetEndPoseName: resolvedTargetEndPoseName,
//        isLooping: isLooping
//    ) else {
//        AppLogger.shared.error("Error: Could not find critical pose sequence.")
//        return
//    }
//
//    let indexPairs = result.indexPairs
//
//    // Build AnimationSequenceElements
//    for pair in indexPairs {
//        let index = pair[0]
//        let nextIndex = pair[1]
//        let currentPose = criticalPoses[index]
//        let nextPose = criticalPoses[nextIndex]
//
//        let frameCount = computeFrameCountBetweenPoses(
//            currentPoseFrame: currentPose.frame,
//            nextPoseFrame: nextPose.frame,
//            totalFrames: totalFramesInAnimation,
//            isLooping: isLooping
//        )
//
//        let animationSequenceElement = AnimationSequenceElement(
//            animationName: animationName,
//            startPoseName: currentPose.poseName,
//            startPoseFrame: Float(currentPose.frame),
//            startPoseID: currentPose.poseID,
//            endPoseName: nextPose.poseName,
//            endPoseFrame: Float(nextPose.frame),
//            endPoseID: nextPose.poseID,
//            frameCount: frameCount,
//            currentFrame: nil,
//            isPlaying: false,
//            speed: 1,
//            segmentID: UUID().uuidString,
//            animData: nil,
//            customAnimationInfo: nil,
//            customAnimationSegment: nil,
//            blendInfo: nil,
//            blendTree: nil,
//            isFilledOut: isFilledOut
//        )
//
//        currentAnimationSequence.append(animationSequenceElement)
//
//        if nextPose.poseName == resolvedTargetEndPoseName {
//            // Reached the target end pose
//            break
//        }
//
//        if !isLooping, nextIndex == criticalPoses.count - 1 {
//            // For non-looping animations, stop at the last critical pose
//            break
//        }
//    }
//}
//
//
//
//
//func endStartTransitionPoseType(startTransitionPoseType: PoseType) -> PoseType {
//    // Currently, the end transition pose is the same as the start.
//    // This logic can be expanded if the relationship between start and end changes.
//    return startTransitionPoseType
//}
//
//enum ConnectionPath {
//    case connectingPose
//    case inertialization
//    case blendIn
//}
//
//private func getAnimDataPointTarget(
//    initAnimationSequenceElement: AnimationSequenceElement,
//    transitionType: WalkToWalkIntent,
//    dataManager: DataManager
//) -> (animDataPoint: AnimDataPoint, startCriticalPoseIndex: Int)? {
//    switch transitionType {
//    // Change Stride Length
//    case .stride:
//
//        // build modified animation and pull transforms and animDataPoint
//
//        // make sure to pull from the original animation
//        let rawAnimationName = initAnimationSequenceElement.animationName
//        let targetAnimation = rawAnimationName.components(separatedBy: "--").first ?? rawAnimationName
//
//        // Convert optional Float to an Int (using 0 as a fallback if nil)
//        let endPoseFrameAsInt = Int(initAnimationSequenceElement.endPoseFrame ?? 0)
//
//        // Use the refactored function to extract the correct starting frame.
//        let startingFrame = extractEndFrameFromAnimName(from: rawAnimationName, fallback: endPoseFrameAsInt) // TODO: incorrect!
//
//        if printBrainSystem {
//            AppLogger.shared.anim("Building AnimDataPont for stride, Starting frame for stride animation is \(startingFrame) for animation \(targetAnimation) from animation \(rawAnimationName)")
//        }
//
//        guard let (transformDataPoint, animDataPointTarget) = createStrideAnimDataPoint(
//            animationName: targetAnimation,
//            startingFrame: startingFrame,
//            highPoseSide: initAnimationSequenceElement.endPoseName.sideOnGround.otherSide, // side in the initial high pose
//            dataManager: dataManager
//        ) else {
//            AppLogger.shared.error("Error: Could not create stride animation data points.")
//            return nil
//        }
//        // Add both the transform and animation data together using the new unified method.
//        dataManager.addGeneratedData(name: animDataPointTarget.animationName,
//                                     animationData: animDataPointTarget,
//                                     transformData: transformDataPoint)
//
//        return (animDataPointTarget, 0)
//
//
//    // revert to the original animation
//    case .origWalk:
//        // make sure to pull from the original animation
//        let rawAnimationName = initAnimationSequenceElement.animationName
//        let targetAnimation = rawAnimationName.components(separatedBy: "--").first ?? rawAnimationName
//
//        // Convert optional Float to an Int (using 0 as a fallback if nil)
//        let endPoseFrameAsInt = Int(initAnimationSequenceElement.endPoseFrame ?? 0)
//
//        // Use the refactored function to extract the correct starting frame.
//        let startingFrame = extractEndFrameFromAnimName(from: rawAnimationName, fallback: endPoseFrameAsInt)
//
//        if printBrainSystem {
//            AppLogger.shared.anim("DEBUG: Building AnimDataPont for origWalk, Starting frame for stride animation is \(startingFrame) for animation \(targetAnimation) from animation \(rawAnimationName)")
//        }
//
//        guard let animDataPointTarget = dataManager.getAnimDataPoint(for: targetAnimation) else {
//            AppLogger.shared.error("Error: Animation data not found for \(initAnimationSequenceElement.animationName)")
//            return nil
//        }
//
//        // find animDataPointTarget.criticalPoses index corresponding to startingFrame
//        guard let startCriticalPoseIndex = animDataPointTarget.criticalPoses.binarySearchIndex(for: startingFrame) else {
//            AppLogger.shared.error("Error: No critical pose found at or after frame \(startingFrame) in animation \(targetAnimation)")
//            return nil
//        }
//        // if we are getting the last index in the critical poses, loop back if possible
//        let adjustedIndex: Int
//        if animDataPointTarget.isLoop, startCriticalPoseIndex == animDataPointTarget.criticalPoses.count - 1 {
//            adjustedIndex = 0
//        } else {
//            adjustedIndex = startCriticalPoseIndex
//        }
//
//        return (animDataPointTarget, adjustedIndex)
//
//    // Change Direction
//    case .cirWalk(.left), .cirWalk(.right): // TODO: now hacked to do only left side
//
//        // build modified animation and pull transforms and animDataPoint
//
//        // make sure to pull from the original animation
//        let rawAnimationName = initAnimationSequenceElement.animationName
//        let targetAnimation = rawAnimationName.components(separatedBy: "--").first ?? rawAnimationName
//
//        // Convert optional Float to an Int (using 0 as a fallback if nil)
//        let startingFrame = Int(initAnimationSequenceElement.endPoseFrame ?? 0)
//
//        if printBrainSystem {
//            AppLogger.shared.anim("Building AnimDataPont for cirWalk, Starting frame for CIR animation is \(startingFrame) for animation \(targetAnimation) from animation \(rawAnimationName)")
//        }
//        
//        guard let startCriticalPoseIndex =  dataManager.getIndexOfCriticalPose(for: rawAnimationName, at: startingFrame) else {
//            AppLogger.shared.error("Error: No critical pose found at frame \(startingFrame) in animation \(targetAnimation)")
//            return nil
//        }
//        
//        
//        // TODO: hack for now
//        var endCriticalPoseIndex = startCriticalPoseIndex - 1
//        if startCriticalPoseIndex == 0 { // if we are at the end of the animation, loop
//            endCriticalPoseIndex = 2
//        }
//
//        guard let (transformDataPoint, animDataPointTarget) = createCirWalkAnimAndTransformDataPoints(
//            animationName: targetAnimation,
//            startCriticalPoseIndexIncl: startCriticalPoseIndex,
//            endCriticalPoseIndexExcl: endCriticalPoseIndex,
//            changeInOrientationDegrees: 90,
//            dataManager: dataManager
//        ) else {
//            AppLogger.shared.error("Error: Could not create cirWalk animation and Transform data points for \(targetAnimation).")
//            return nil
//        }
//        // Add both the transform and animation data together using the new unified method.
//        dataManager.addGeneratedData(name: animDataPointTarget.animationName,
//                                     animationData: animDataPointTarget,
//                                     transformData: transformDataPoint)
//
//        return (animDataPointTarget, 0)
//
//
//    default:
//        AppLogger.shared.error("Error: Unsupported transition type: \(transitionType).")
//        return nil // I have not implemented it yet, and it may require inertialization or blend in anyway
//    }
//}
//
///// Extracts the end frame from an animation name containing -- information.
///// - Parameters:
/////   - animationName: The full animation name string.
/////   - fallback: A fallback value (typically the endPoseFrame) if no valid end frame is found.
///// - Returns: The extracted end frame as an Int, or the fallback if extraction fails.
//private func extractEndFrameFromAnimName(from animationName: String, fallback: Int) -> Int {
//    guard animationName.contains("--") else { return fallback }
//    let strideComponents = animationName.components(separatedBy: "--")
//    guard strideComponents.count > 1 else { return fallback }
//
//    let afterStride = strideComponents[1]
//    let tokens = afterStride.components(separatedBy: "_")
//
//    // Look for the token that starts with "endFrame" and extract the number after it.
//    for token in tokens {
//        if token.hasPrefix("endFrame") {
//            let numberString = token.replacingOccurrences(of: "endFrame", with: "")
//            if let endFrame = Int(numberString) {
//                return endFrame
//            }
//        }
//    }
//    return fallback
//}
//
//func buildConnectionPoseSequence(
//    animationSequence: inout [AnimationSequenceElement],
//    initIndex: Int,
//    transitionType: WalkToWalkIntent,
//    dataManager: DataManager
//) -> Bool {
//    let initAnimationSequenceElement = animationSequence[initIndex]
//    // obtain or construct target animation data
//    guard let (animDataPointTarget, startCriticalPoseIndex) = getAnimDataPointTarget(initAnimationSequenceElement: initAnimationSequenceElement, transitionType: transitionType, dataManager: dataManager)
//    else {
//        AppLogger.shared.error("Error: Failed to get target animation data for \(initAnimationSequenceElement.animationName).")
//        return false // failed to build new animation sequence
//    }
//
//    // build target animation sequence that directly connects with current initIndex segment
//    let targetAnimationSequence = constructAnimationSubSequenceForGivenAnimation(from: animDataPointTarget, startCriticalPoseIndex: startCriticalPoseIndex, endCriticalPoseIndex: animDataPointTarget.criticalPoses.count - 1)
//
//    if printBrainSystem {
//        AppLogger.shared.anim("Built segement sequence for: \(targetAnimationSequence[0].animationName) with start pose \(targetAnimationSequence[0].startPoseName) and count of segments \(targetAnimationSequence.count).\nAnimation Sequence is: \(targetAnimationSequence.map { "\($0.animationName) from \($0.startPoseFrame ?? -1) to \($0.endPoseFrame ?? -1)" })")
//    }
//
//    // Discard the existing segments after init index and insert the new ones
//    if initIndex < animationSequence.count - 1 {
//        animationSequence.removeSubrange((initIndex + 1)...)
//    }
//    animationSequence.append(contentsOf: targetAnimationSequence)
//    return true
//}
