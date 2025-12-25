#!/usr/bin/env python3
from pathlib import Path; import concat_sources_lib as c; OUTPUT_FILENAME = "concatenated_MVR.txt"; SECONDARY_OUTPUT_PATH = Path("/Users/nata/Desktop/temp/concatenated.txt"); OUTPUT_FILENAME_temp = "concatenated_MVR_temp.txt"; SECONDARY_OUTPUT_PATH_temp = Path("/Users/nata/Desktop/temp/concatenated_temp.txt")

# # Relative paths of files to concatenate 
SOURCE_FILES_TEMP = [

]



SOURCE_FILES = [
    
    # ============================================================================
    # Project Structure
    # ============================================================================
    "_concat/project_structure-MatheMagicApp.text",
    "_concat/project_structure-AILib.text",
    "_concat/project_structure-AnimLib.text",
    # "_concat/project_structure-AssetLib.text",
    "_concat/project_structure-CoreLib.text",
    "_concat/project_structure-Inertialization.text",
    # "_concat/project_structure-joystickController.text",

    # ============================================================================
    # APP (MatheMagicApp)
    # ============================================================================

    "MatheMagicApp/Info.plist",

    #----------------------------------------------------------------------------
    # APP: Components
    #----------------------------------------------------------------------------
    # "MatheMagicApp/Components/CameraRotationComponent.swift",
    "MatheMagicApp/Components/MoveComponent.swift",
    # "MatheMagicApp/Components/RealityViewExtensions.swift",
    # "MatheMagicApp/Components/TapComponent.swift",

    #----------------------------------------------------------------------------
    # APP: Entities
    #----------------------------------------------------------------------------
    # "MatheMagicApp/Entities/EntityEntries.swift",

    #----------------------------------------------------------------------------
    # APP: Environment
    #----------------------------------------------------------------------------
    # "MatheMagicApp/Environment/SkyboxUtilities.swift",

    #----------------------------------------------------------------------------
    # APP: Game Engine
    #----------------------------------------------------------------------------
    # "MatheMagicApp/Game Engine/GameMachineStates.swift",
    # "MatheMagicApp/Game Engine/GlobalEntities.swift",
    # "MatheMagicApp/Game Engine/PlayData.swift",

    #----------------------------------------------------------------------------
    # APP: Load
    #----------------------------------------------------------------------------
    # "MatheMagicApp/Load/PreLoadAssets.swift",

    #----------------------------------------------------------------------------
    # APP: AI
    #----------------------------------------------------------------------------
    "MatheMagicApp/AI/MatheMagicAIConfig.swift",
    "MatheMagicApp/AI/AIEndpointConfig.swift",
    "MatheMagicApp/AI/MatheMagicAIContract.swift",
    "MatheMagicApp/AI/MatheMagicAIEventPipeline.swift",
    "MatheMagicApp/AI/MatheMagicAIService.swift",
    "MatheMagicApp/AI/AIDebugState.swift",

    #----------------------------------------------------------------------------
    # APP: Top-Level
    #----------------------------------------------------------------------------
    "MatheMagicApp/Top-Level/AppState.swift",
    "MatheMagicApp/Top-Level/ContentView.swift",
    # "MatheMagicApp/Top-Level/GameModel.swift",
    "MatheMagicApp/Top-Level/GameModelView.swift",
    "MatheMagicApp/Top-Level/ImmersiveVew.swift",
    "MatheMagicApp/Top-Level/RealityTextInputState.swift",
    # "MatheMagicApp/Top-Level/MatheMagicApp.swift",

    #----------------------------------------------------------------------------
    # APP: Utilities
    #----------------------------------------------------------------------------
    # "MatheMagicApp/Utilities/ExtensionsEntity.swift",
    # "MatheMagicApp/Utilities/LocalUtilities.swift",

    #----------------------------------------------------------------------------
    # APP: Views
    #----------------------------------------------------------------------------
    # "MatheMagicApp/Views/BallView.swift",
    # "MatheMagicApp/Views/CustomButtonStyle.swift",
    # "MatheMagicApp/Views/GameOver.swift",
    # "MatheMagicApp/Views/Lobby.swift",
    # "MatheMagicApp/Views/Play.swift",
    # "MatheMagicApp/Views/AnimationDebugHUDOverlayView.swift",
    "MatheMagicApp/Views/AIResponseHUDView.swift",
    "MatheMagicApp/Views/RealityTextInputOverlayView.swift",
    # "MatheMagicApp/Views/Selection.swift",
    # "MatheMagicApp/Views/Start.swift",

    #----------------------------------------------------------------------------
    # APP: Views / Scene Functions
    #----------------------------------------------------------------------------
    # "MatheMagicApp/Views/Scene Functions/SceneManager.swift",
    "MatheMagicApp/Views/Scene Functions/setupCharacterWithComponents.swift",

    # ============================================================================
    # AI LIBRARY (AILibS)
    # ============================================================================

    #----------------------------------------------------------------------------
    # AI: External
    #----------------------------------------------------------------------------
    "AILibS/ClassifierKit/AIJSONContract.swift",
    "AILibS/ClassifierKit/AIJSONRunModels.swift",
    "AILibS/ClassifierKit/AILibConnection.swift",
    "AILibS/ClassifierKit/ClassifierError.swift",
    "AILibS/ClassifierKit/MCQFilledResponse.swift",
    "AILibS/ClassifierKit/MCQKey.swift",
    "AILibS/ClassifierKit/ClassifierRunner.swift",
    "AILibS/ClassifierKit/MCQTemplate.swift",
    "AILibS/ClassifierKit/OllamaChatModels.swift",
    
    #----------------------------------------------------------------------------
    # AI: Internal
    #----------------------------------------------------------------------------
    # "AILibS/ClassifierKit/ClassifierKitLogger.swift",
    # "AILibS/ClassifierKit/JSONSchema.swift",
    # "AILibS/ClassifierKit/JSONSchemaValidator.swift",
    # "AILibS/ClassifierKit/JSONValue.swift",
    # "AILibS/ClassifierKit/MCQSchemaBuilder.swift",
    # "AILibS/ClassifierKit/ModelOutputJSONExtractor.swift",
    # "AILibS/ClassifierKit/OllamaClient.swift",
    # "AILibS/ClassifierKit/OllamaEndpointParser.swift",
    # "AILibS/ClassifierKit/OllamaJSONFiller.swift",
    # "AILibS/ClassifierKit/PromptBuilder.swift",
    # "AILibS/ClassifierKit/SchemaPromptBuilder.swift",
    # "AILibS/ClassifierKit/StrictJSONPromptBuilder.swift",

    # ============================================================================
    # ANIMATION LIBRARY (AnimLibS)
    # ============================================================================

    #----------------------------------------------------------------------------
    # ANIMATION: Transforms
    #----------------------------------------------------------------------------
    # "AnimLibS/AnimationTransforms/PlayTransforms.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Transforms / Transforms-To-Play
    #----------------------------------------------------------------------------
    "AnimLibS/AnimationTransforms/Transforms-To-Play/0-TransformsToPlay.swift",
    # "AnimLibS/AnimationTransforms/Transforms-To-Play/1-orig-data.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Transforms / Transforms-To-Play / 2-Alterations Data Functions
    #----------------------------------------------------------------------------
    "AnimLibS/AnimationTransforms/Transforms-To-Play/2-Alterations Data Functions/cirWalk-data.swift",
    "AnimLibS/AnimationTransforms/Transforms-To-Play/2-Alterations Data Functions/matchTransform-data.swift",
    "AnimLibS/AnimationTransforms/Transforms-To-Play/2-Alterations Data Functions/stride-data.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Transforms / Transforms-To-Play (continuation)
    #----------------------------------------------------------------------------
    "AnimLibS/AnimationTransforms/Transforms-To-Play/2-apply-alterations-pre-blend.swift",
    # "AnimLibS/AnimationTransforms/Transforms-To-Play/3-blend-elments-in-tree.swift",
    # "AnimLibS/AnimationTransforms/Transforms-To-Play/4-inertial-data.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Transitions
    #----------------------------------------------------------------------------

    #----------------------------------------------------------------------------
    # ANIMATION: Transitions / Construct Poses / 0-Pose-Level
    #----------------------------------------------------------------------------
    # "AnimLibS/AnimationTranstions/Construct Poses/0-Pose-Level/AdjustPose-Idle.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Transitions / Construct Poses / 1-Body-Part-Level
    #----------------------------------------------------------------------------
    # "AnimLibS/AnimationTranstions/Construct Poses/1-Body-Part-Level/AdjustBodyParts.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Transitions / Construct Poses / Bones-Level
    #----------------------------------------------------------------------------
    # "AnimLibS/AnimationTranstions/Construct Poses/Bones-Level/AboutToLiftFoot-Idle.swift",
    # "AnimLibS/AnimationTranstions/Construct Poses/Bones-Level/LiftFoot-Idle.swift",
    # "AnimLibS/AnimationTranstions/Construct Poses/Bones-Level/PlantedFeetIfPossible-Idle.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Transitions / Construct Poses / Specific-Bone-Functions
    #----------------------------------------------------------------------------
    # "AnimLibS/AnimationTranstions/Construct Poses/Specific-Bone-Functions/AdjustCalf.swift",
    # "AnimLibS/AnimationTranstions/Construct Poses/Specific-Bone-Functions/CorrectHipHeight.swift",
    # "AnimLibS/AnimationTranstions/Construct Poses/Specific-Bone-Functions/ExtendFoot.swift",
    # "AnimLibS/AnimationTranstions/Construct Poses/Specific-Bone-Functions/MoveBonesUtilities.swift",
    # "AnimLibS/AnimationTranstions/Construct Poses/Specific-Bone-Functions/OrientThigh.swift",
    # "AnimLibS/AnimationTranstions/Construct Poses/Specific-Bone-Functions/RollThigh.swift",
    # "AnimLibS/AnimationTranstions/Construct Poses/Specific-Bone-Functions/TiltPelvis.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Transitions / Idle-Idle Transitions
    #----------------------------------------------------------------------------
    # "AnimLibS/AnimationTranstions/Idle-Idle Transitions/0-fillOutIdeToIdleElements.swift",
    # "AnimLibS/AnimationTranstions/Idle-Idle Transitions/addAdditiveSourceElement.swift",
    # "AnimLibS/AnimationTranstions/Idle-Idle Transitions/addAdditiveSourceElementFromTr.swift",
    # "AnimLibS/AnimationTranstions/Idle-Idle Transitions/addBlendInSourceElementFromCustomInfo.swift",
    # "AnimLibS/AnimationTranstions/Idle-Idle Transitions/addTargetAnimationSequenceAfterIdleToIdle.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Transitions / Idle-Walk Transitions
    #----------------------------------------------------------------------------
    # "AnimLibS/AnimationTranstions/Idle-Walk Transitions/addBlendInSourceElement.swift",
    # "AnimLibS/AnimationTranstions/Idle-Walk Transitions/fillWalkIdleElements.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Transitions / Walk-Walk Transitions / CirWalk
    #----------------------------------------------------------------------------
    # "AnimLibS/AnimationTranstions/Walk-Walk Transitions/CirWalk/CirWalk.swift",
    # "AnimLibS/AnimationTranstions/Walk-Walk Transitions/CirWalk/CirWalkBoneOffsets.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Transitions / Walk-Walk Transitions / Stride
    #----------------------------------------------------------------------------
    # "AnimLibS/AnimationTranstions/Walk-Walk Transitions/Stride/StrideFunctions.swift",
    # "AnimLibS/AnimationTranstions/Walk-Walk Transitions/Stride/StrideMIN-toDelete.swift",
    # "AnimLibS/AnimationTranstions/Walk-Walk Transitions/Stride/StrideMain.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Brain
    #----------------------------------------------------------------------------
    "AnimLibS/Brain/BrainAnimationSequence.swift",
    "AnimLibS/Brain/Travel&StyleEvents.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Brain / Idle
    #----------------------------------------------------------------------------
    "AnimLibS/Brain/Idle/0-IdleSequence.swift",
    # "AnimLibS/Brain/Idle/1-eval-orientation.swift",
    "AnimLibS/Brain/Idle/2-pick-transition.swift",
    # "AnimLibS/Brain/Idle/3-build-transition.swift",
    # "AnimLibS/Brain/Idle/4-inertial-units.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Brain / Walk
    #----------------------------------------------------------------------------
    "AnimLibS/Brain/Walk/0-WalkSequence.swift",
    "AnimLibS/Brain/Walk/1-PathwayEval.swift",
    "AnimLibS/Brain/Walk/2-ExtendWalkSequence.swift",
    # "AnimLibS/Brain/Walk/3-TranstionalSequence.swift",
    # "AnimLibS/Brain/Walk/4-StepAlterations.swift",
    # "AnimLibS/Brain/Walk/5-InertialUnits.swift",
    "AnimLibS/Brain/Walk/6-walkToIdle.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Components
    #----------------------------------------------------------------------------
    # "AnimLibS/Components/AnimationSystem.swift",
    # "AnimLibS/Components/AnimationPlaybackStateComponent.swift",
    "AnimLibS/Components/BrainComponent.swift",
    # "AnimLibS/Components/CustomAnimationSystem.swift",
    "AnimLibS/Components/EventComponent.swift",
    # "AnimLibS/Components/SkeletalPosesSystem.swift",
    # "AnimLibS/Components/TravelComponent.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: SettingsAndDataStructs
    #----------------------------------------------------------------------------
    "AnimLibS/SettingsAndDataStructs/AnimationSettings.swift",
    # "AnimLibS/SettingsAndDataStructs/CharacterAttachment.swift",
    # "AnimLibS/SettingsAndDataStructs/SequenceData.swift",
    "AnimLibS/SettingsAndDataStructs/StyleGuide.swift",
    "AnimLibS/SettingsAndDataStructs/TravelGuide.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Utilities
    #----------------------------------------------------------------------------
    # "AnimLibS/Utilities/AnimationDebugHUD.swift",
    # "AnimLibS/Utilities/BuildTransforms.swift",
    # "AnimLibS/Utilities/CommonUseCases.swift",
    # "AnimLibS/Utilities/CriricalPoseFunctions.swift",
    # "AnimLibS/Utilities/SkeletonUtilities.swift",
    # "AnimLibS/Utilities/TransformUtilities.swift",
    # "AnimLibS/Utilities/mathUtilities.swift",

    #----------------------------------------------------------------------------
    # ANIMATION: Utilities / Sequence Functions
    #----------------------------------------------------------------------------
    # "AnimLibS/Utilities/Sequence Functions/CreateAnimationSequence.swift",
    # "AnimLibS/Utilities/Sequence Functions/addBlendInSourceElementWithCustomAnimation.swift",

    # ============================================================================
    # ASSET LIBRARY (AssetLibS)
    # ============================================================================

    #----------------------------------------------------------------------------
    # ASSET: AssetEntity
    #----------------------------------------------------------------------------
    # "AssetLibS/AssetEntity/TeraEntries.swift",
    # "AssetLibS/AssetEntity/TeraModelDictionaryActor.swift",
    # "AssetLibS/AssetEntity/TeraSet.swift",

    #----------------------------------------------------------------------------
    # ASSET: BuildTerrain
    #----------------------------------------------------------------------------
    # "AssetLibS/BuildTerrain/SimpleTerrainMaterial.swift",
    # "AssetLibS/BuildTerrain/TerrainHeight.swift",
    # "AssetLibS/BuildTerrain/TerrainMeshBuilder.swift",
    # "AssetLibS/BuildTerrain/TerrainModelEntityLoader.swift",

    #----------------------------------------------------------------------------
    # ASSET: Components
    #----------------------------------------------------------------------------
    # "AssetLibS/Components/TeraComponent.swift",

    #----------------------------------------------------------------------------
    # ASSET: Import
    #----------------------------------------------------------------------------
    # "AssetLibS/Import/AssetManager.swift",
    # "AssetLibS/Import/ImportMaterial.swift",
    # "AssetLibS/Import/ImportTerrain.swift",

    # ============================================================================
    # CORE LIBRARY (CoreLibS)
    # ============================================================================

    #----------------------------------------------------------------------------
    # CORE: Components
    #----------------------------------------------------------------------------
    # "CoreLibS/Components/DataCenterComponent.swift",

    #----------------------------------------------------------------------------
    # CORE: CoreEntity
    #----------------------------------------------------------------------------
    # "CoreLibS/CoreEntity/EntityExtensions.swift",
    # "CoreLibS/CoreEntity/EntitySet.swift",
    # "CoreLibS/CoreEntity/ModelEntityUtilities.swift",

    #----------------------------------------------------------------------------
    # CORE: CoreUtilities
    #----------------------------------------------------------------------------
    # "CoreLibS/CoreUtilities/AdditiveOffsetsForCirWalk.swift",
    # "CoreLibS/CoreUtilities/AppLogger.swift",
    # "CoreLibS/CoreUtilities/CoreTransform.swift",
    # "CoreLibS/CoreUtilities/SmoothingUtilities.swift",
    # "CoreLibS/CoreUtilities/VectorMath.swift",

    #----------------------------------------------------------------------------
    # CORE: ImportData
    #----------------------------------------------------------------------------
    # "CoreLibS/ImportData/BoneOperations.swift",
    # "CoreLibS/ImportData/CommonStructs.swift",
    # "CoreLibS/ImportData/CriticalPosesFunctions.swift",
    # "CoreLibS/ImportData/DataManager.swift",
    # "CoreLibS/ImportData/GeneratedAnimCache.swift",
    # "CoreLibS/ImportData/ImportAnim.swift",
    # "CoreLibS/ImportData/ImportMap.swift",
    # "CoreLibS/ImportData/ImportTransforms.swift",
    # "CoreLibS/ImportData/ImportTransitions.swift",
    # "CoreLibS/ImportData/Mirror.swift",
    # "CoreLibS/ImportData/ReOrderJointsAtLoad.swift",

    # ============================================================================
    # INERTIALIZATION LIBRARY (InertializationS)
    # ============================================================================
    # "InertializationS/inert-caching-unused.swift",
    # "InertializationS/inert-main.swift",

    # ============================================================================
    # JOYSTICK CONTROLLER (joystickControllerS)
    # ============================================================================
    "joystickControllerS/ExternalDataProtocol.swift",
    # "joystickControllerS/JoystickInterpreter.swift",

    #----------------------------------------------------------------------------
    # JOYSTICK: UI
    #----------------------------------------------------------------------------
    "joystickControllerS/UI/ActionButtonView.swift",
    "joystickControllerS/UI/JoystickController.swift",
]

if __name__ == "__main__":
    path, total_chars, comment_chars, total_bytes, per_file_stats = c.concatenate_sources(SOURCE_FILES, OUTPUT_FILENAME, SECONDARY_OUTPUT_PATH); c._print_report(path, total_chars, comment_chars, total_bytes, per_file_stats); source_files_temp = globals().get("SOURCE_FILES_TEMP")
    if source_files_temp:
        t_path, t_chars, t_comments, t_bytes, t_stats = c.concatenate_sources_for(source_files_temp, OUTPUT_FILENAME_temp, SECONDARY_OUTPUT_PATH_temp);c._print_report(t_path, t_chars, t_comments, t_bytes, t_stats)
    print(f"Completed at {c.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
