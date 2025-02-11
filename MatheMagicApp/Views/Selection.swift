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
    @State private var selectedCharacter: SelectedCharacter? = nil

    @EnvironmentObject var gameModelView: GameModelView

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1) RealityView as the "background"
                RealityView { content in
                    content.add(spaceOrigin)

                    // Skybox
                    do {
                        let skyboxResource = try await EnvironmentResource(named: "FantasyCastle")
                        content.environment = RealityViewEnvironment.skybox(skyboxResource)
                    } catch {
                        print("Error loading fantasycastle skybox: \(error)")
                    }

                    // Image-based lighting
                    do {
                        let env = try await EnvironmentResource(named: "ImageBasedLighting")
                        let probe = VirtualEnvironmentProbeComponent.Probe(environment: env)
                        spaceOrigin.components.set(
                            VirtualEnvironmentProbeComponent(source: .single(probe))
                        )
                    } catch {
                        print("Error loading IBL: \(error)")
                    }

                    // Add a point light to spaceOrigin
                    let pointLight = PointLightComponent(
                        color: .white,
                        intensity: 26963.76,
                        attenuationRadius: 10.0
                    )
                    let lightEntity = Entity()
                    lightEntity.components.set(pointLight)
                    lightEntity.transform.translation = simd_float3(0.5, 0.5, 0)
                    spaceOrigin.addChild(lightEntity)
                }
                .id("SingleRealityView")
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea()

                // 2) Title Text Overlaid at the Top Center
                VStack {
                    selectionButton2
                        .padding(.top, 50)

                    /*Text("Choose a character!")
                        .font(.custom("TimesNewRomanPS-BoldMT", size: 50))
                        .foregroundColor(.white)
                        .padding(.top, 30)*/
                    Spacer()
                }
                .frame(width: geometry.size.width)

                // 3) Two Image Buttons at the Bottom
                VStack {
                    Spacer()
                    HStack(spacing: 300) {
                        // Left Image Button (for Raven)
                        Button(action: {
                            selectedCharacter = .left
                            print("Left character selected")

                            // Remove any existing child entities
                            spaceOrigin.children.removeAll()

                            // Add the raven entity, shifted downward
                            if let ravenModel = entityModelDictionary["raven"] {
                                ravenModel.entity.transform.translation = simd_float3(0, -1, 0)
                                spaceOrigin.addChild(ravenModel.entity)
                            }
                        }) {
                            Text("Raven")
                        }
                        .buttonStyle(CustomButtonStyle())

                        // Right Image Button (for Flash)
                        Button(action: {
                            selectedCharacter = .right
                            print("Right character selected")

                            // Remove any existing child entities
                            spaceOrigin.children.removeAll()

                            // Add the flash entity, shifted downward
                            if let flashModel = entityModelDictionary["flash"] {
                                flashModel.entity.transform.translation = simd_float3(0, -1, 0)
                                spaceOrigin.addChild(flashModel.entity)
                            }
                        }) {
                            Text("Flash")
                        }
                        .buttonStyle(CustomButtonStyle())
                    }
                    .padding(.bottom, 50)
                }
            }
            .background(Color.white.ignoresSafeArea())
        }
    }

    // Reusable "Go back to Lobby" Button
    private var selectionButton2: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.5)) {
                spaceOrigin.children.removeAll()

                spaceOriginBall.isEnabled = false
                gameModelView.lobby()
            }
        }) {
            Text("Go back to Lobby")
                .font(.custom("TimesNewRomanPS-BoldMT", size: 30)) // Half of 40
                .foregroundColor(.white)
                .padding()
                .frame(width: 350, height: 50) // Wider but half as tall
                .background(Color(red: 81/255, green: 156/255, blue: 72/255))
                .cornerRadius(15) // Half of 30
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(red: 60/255, green: 115/255, blue: 53/255), lineWidth: 1) // Half of 2
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(red: 136/255, green: 219/255, blue: 125/255), lineWidth: 3) // Half of 6
                )
                .shadow(color: Color(red: 0/255, green: 100/255, blue: 0/255).opacity(0.5), radius: 5, x: 0, y: 5) // Half of original shadows
                .shadow(color: .black.opacity(0.3), radius: 2.5, x: 0, y: 2.5)
        }
        //.scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        //.animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        .padding(.bottom, 50)
    }

    
}
