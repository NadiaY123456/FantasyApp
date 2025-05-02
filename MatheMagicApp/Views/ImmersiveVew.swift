import AnimLib
import CoreLib

import joystickController
import RealityKit
import RealityKitContent
import SwiftUI

struct Selection: View {
    // State variable to track the selected character
    @StateObject private var sceneManager = SceneManager() // Create a dedicated manager
    @EnvironmentObject var gameModelView: GameModelView

    // This variable tracks the starting angle when a drag begins.
    @State private var dragStartAngle: Angle = .zero
    @GestureState private var dragOffset: CGSize = .zero
    @State private var lastDragTranslation: CGSize = .zero
    @State private var lastDragUpdateTime: TimeInterval = CACurrentMediaTime()
    @State private var lastDeltaX: CGFloat = 0.0
    @State private var dragBaseline: CGFloat = 0.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1) RealityView as the "background"
                RealityView { content in
                    // Initial setup
                    content.add(spaceOrigin)

                    // Add directional light
                    sceneManager.addDirectionalLight(to: spaceOrigin)

                    // Add point light
                    // sceneManager.addPointLight(to: spaceOrigin)

                    // Image-based lighting (IBL)
                    guard let iblComponent = try? await sceneManager.addImageBasedLight(name: "ImageBasedLighting") else { return }
                    spaceOrigin.components.set(iblComponent) // space origin emits light

                    // position the camera immeditely on load to avoid a blink
                    GameModelView.shared.camera.updateCameraTransform(deltaTime: 0.0)

                    // Skybox
                    GameModelView.shared.camera.loadSkybox(into: content, for: .forest, with: iblComponent) // This loads png image as skybox

//                     // This function loads proper skybox (i.e. .exr) and uses it as IBL light source
//                     do {
//                         let skyboxResource = try await EnvironmentResource(named: "kloofendal_48d_partly_cloudy_puresky")
//                         content.environment = RealityViewEnvironment.skybox(skyboxResource)
//                     } catch {
//                         AppLogger.shared.error("Error loading fantasycastle skybox: \(error)")
//                     }

                    // add environment
                    if let planeModel = entityModelDictionaryCore["plane"] {
                        spaceOrigin.addChild(planeModel.entity)
                        // print plane position
                        AppLogger.shared.info("Plane position: \(planeModel.entity.transform.translation)")
                    }

                    // Add the character and create the camera pivot around it.
                    let flashModel = setupCharacterWithComponents(entityDictionaryID: "flash")
                    // Optionally, add lighting to Flash and add to the scene.
                    sceneManager.addContentWithLight(entity: flashModel, iblComponent: iblComponent)
                    // Set Flash as the tracked entity.
                    GameModelView.shared.camera.trackedEntity = flashModel
                    // Add the camera relative to Flash.
                    GameModelView.shared.camera.addCamera(to: content, relativeTo: flashModel, deltaTime: 0)

                    AppLogger.shared.info("Plane position: \(flashModel.transform.translation)")
                }
                .id("SingleRealityView")
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea()

                // MARK: - Gesture Modifiers for Orbiting

                // One-finger drag for rotation.
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            GameModelView.shared.rawDragTranslation = value.translation
                            GameModelView.shared.isDragging = true
                        }
                        .onEnded { _ in
                            GameModelView.shared.isDragging = false
                            GameModelView.shared.rawDragTranslation = .zero
                        }
                )
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { scale in
                            if !GameModelView.shared.isPinching {
                                // Capture the baseline when pinch begins.
                                GameModelView.shared.initialPinchScale = scale
                            }
                            GameModelView.shared.isPinching = true
                            GameModelView.shared.rawPinchScale = scale
                        }
                        .onEnded { _ in
                            GameModelView.shared.isPinching = false
                            GameModelView.shared.rawPinchScale = 1.0
                        }
                )
                // 2) Overlay the JoystickView at the bottom left
                VStack {
                    Spacer()
                    HStack {
                        JoystickView(
                            onChange: { magnitude, angle in
                                // Update the game model with the joystick's values.
                                GameModelView.shared.joystickMagnitude = magnitude
                                GameModelView.shared.joystickAngle = angle
                                GameModelView.shared.joystickIsTouching = true
                            },
                            onEnd: {
                                // Reset the joystick values when the user releases the joystick.
                                GameModelView.shared.joystickMagnitude = 0
                                GameModelView.shared.joystickAngle = .zero
                                GameModelView.shared.joystickIsTouching = false
                            }
                        )
                        .padding([.bottom, .leading], 20)
                        Spacer()
                        // ─────────────────────────────────────────────
                        //  ACTION BUTTON  (bottom‑right)
                        //  Keeps GameModelView.shared.isHoldingButton
                        //  true only while pressed.
                        ActionButtonView(
                            onPressStart: { GameModelView.shared.isHoldingButton = true },
                            onPressEnd: { GameModelView.shared.isHoldingButton = false }
                        )
                        .padding([.bottom, .trailing], 20)
                        // ─────────────────────────────────────────────
                    }
                }
            }
            .background(Color.white.ignoresSafeArea())
        }
    }
}
