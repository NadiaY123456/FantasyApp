import CoreLib
import RealityKit
import RealityKitContent
import SwiftUI

// Enum to represent the selected character
enum SelectedCharacter {
    case left
    case right
}

struct Selection: View {
    // State variable to track the selected character
    @StateObject private var sceneManager = SceneManager() // Create a dedicated manager
    @State private var selectedCharacter: SelectedCharacter? = nil
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
                    
                    GameModelView.shared.camera.updateCameraTransform()

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
                    }

                    // Add the character and create the camera pivot around it.
                    // For this example, we assume Flash is the default tracked character.
                    if let flashModel = entityModelDictionaryCore["flash"] {
                        // Ensure Flash is added to the scene.
                        if flashModel.entity.parent == nil {
                            spaceOrigin.addChild(flashModel.entity)
                        }
                        // Set Flash as the tracked entity.
                        GameModelView.shared.camera.trackedEntity = flashModel.entity
                        // Add the camera relative to Flash.
                        GameModelView.shared.camera.addCamera(to: content, relativeTo: flashModel.entity)
                        // Optionally, add lighting to Flash.
                        sceneManager.addContentWithLight(entity: flashModel.entity, iblComponent: iblComponent)
                    }
                    
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
                            GameModelView.shared.isPinching = true
                            GameModelView.shared.rawPinchScale = scale
                        }
                        .onEnded { _ in
                            GameModelView.shared.isPinching = false
                            GameModelView.shared.rawPinchScale = 1.0
                        }
                )


                // 2) Title Text Overlaid at the Top Center
                VStack {
                    backToLobbyButton
                        .padding(.top, 50)
                    Spacer()
                }
                .frame(width: geometry.size.width)

                // 3) Two Character Buttons at the Bottom
                VStack {
                    Spacer()
                    HStack(spacing: 300) {
                        // Left (Raven) Button
                        CharacterButton(title: "Raven") {
                            selectCharacter(.left)
                        }

                        // Right (Flash) Button
                        CharacterButton(title: "Flash") {
                            selectCharacter(.right)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .background(Color.white.ignoresSafeArea())
        }
    }

    // Reusable "Go back to Lobby" Button
    private var backToLobbyButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.5)) {
                spaceOrigin.children.removeAll()
                spaceOriginBall.isEnabled = false
                gameModelView.lobby()
            }
        }) {
            Text("Go back to Lobby")
                .font(.custom("TimesNewRomanPS-BoldMT", size: 30))
                .foregroundColor(.white)
                .padding()
                .frame(width: 350, height: 50)
                .background(Color(red: 81/255, green: 156/255, blue: 72/255))
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(red: 60/255, green: 115/255, blue: 53/255), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(red: 136/255, green: 219/255, blue: 125/255), lineWidth: 3)
                )
                .shadow(color: Color(red: 0/255, green: 100/255, blue: 0/255).opacity(0.5), radius: 5, x: 0, y: 5)
                .shadow(color: .black.opacity(0.3), radius: 2.5, x: 0, y: 2.5)
        }
        .padding(.bottom, 50)
    }

    // MARK: - Character Selection Logic

    private func selectCharacter(_ character: SelectedCharacter) {
        selectedCharacter = character
        switch character {
        case .left:
            AppLogger.shared.info("Left character selected")
            // Remove any existing Flash entity
            if let flash = spaceOrigin.getSelfOrDescendent(withName: "flash") {
                spaceOrigin.removeChild(flash)
            }
            // Add Raven entity with an adjusted position
            if let ravenModel = entityModelDictionaryCore["raven"] {
                ravenModel.entity.transform.translation = simd_float3(0, -1, 0)
                spaceOrigin.addChild(ravenModel.entity)
            }
        case .right:
            AppLogger.shared.info("Right character selected")
            // Remove any existing Raven entity
            if let raven = spaceOrigin.getSelfOrDescendent(withName: "raven") {
                spaceOrigin.removeChild(raven)
            }
            // Add Flash entity
            if let flashModel = entityModelDictionaryCore["flash"] {
                spaceOrigin.addChild(flashModel.entity)
            }
        }
    }
}

// MARK: - Reusable Character Button

struct CharacterButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(CustomButtonStyle())
    }
}
