import RealityKit
import RealityKitContent
import SwiftUI

struct BallView: View {
    @State var showQuestion = false // State to show the math question
    @State private var selectedOption: Int? = nil // State for selected option
    // @State private var isHoldingButton: Bool = false // State for circular button
    @EnvironmentObject var gameModelView: GameModelView
    @State private var joystickPosition: CGSize = .zero

    var body: some View {
        GeometryReader { _ in
            ZStack {
                // 1. RealityViewWithTap as the bottom layer
                RealityViewWithTap()
                    .ignoresSafeArea() // Ensures it covers the entire background

                // 2. VStack for "Go back to Lobby" button at the top
                VStack {
                    selectionButton2
                        .padding(.top, 20) // Optional: Add padding from the top edge
                    Spacer()
                }

                // 3. Question Overlay
                if gameModelView.showQuestion {
                    VStack(spacing: 20) {
                        Text("What is 2 + 2?")
                            .font(.custom("TimesNewRomanPS-BoldMT", size: 70))
                            .foregroundColor(.white)
                            .padding(.bottom, 10) // Spacing between question and options

                        // Multiple choice options in a 2x2 grid
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                AnswerButton(option: 1, selectedOption: $selectedOption)
                                AnswerButton(option: 2, selectedOption: $selectedOption)
                            }
                            HStack(spacing: 10) {
                                AnswerButton(option: 3, selectedOption: $selectedOption)
                                AnswerButton(option: 4, selectedOption: $selectedOption) // Correct answer
                            }
                        }
                    }
                    .padding()
                    .frame(width: 600) // Constrain width of the entire box
                    .background(Color(red: 143/255, green: 196/255, blue: 144/255).opacity(0.9)) // Green background
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 5)
                    )
                    .transition(.opacity) // Opacity transition
                    .animation(.easeInOut(duration: 0.5), value: gameModelView.showQuestion) // Tie animation to showQuestion
                    .onChange(of: selectedOption) { _ in
                        print("Debug: Answer selected")
                        guard let _ = selectedOption else { return }

                        // Fade out the question box after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                print("Debug: Question box going away!!")
                                gameModelView.showQuestion = false
                                print("Value of showQuestion: \(gameModelView.showQuestion)")
                            }
                        }

                        selectedOption = nil
                    }
                }

                // 4. Circular Button Overlay at Bottom Left
                VStack {
                    Spacer()
                    HStack {
                        joystick
                            .padding([.bottom, .leading], 20) // Adjust padding as needed
                        Spacer()
                    }
                }
            }
            .background(Color.white.ignoresSafeArea()) // Ensure the background doesn't interfere
        }
        .onChange(of: gameModelView.showQuestion) { newValue in
            print("BallView detected showQuestion change to \(newValue)")
        }
    }

    private var joystick: some View {
        ZStack {
            // Base Circle
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 170, height: 170)

            // Joystick Handle (styled like CustomButtonStyle)
            Circle()
                .fill(Color(red: 81/255, green: 156/255, blue: 72/255)) // Main green color
                .frame(width: 90, height: 90)
                .overlay(
                    Circle()
                        .stroke(Color(red: 60/255, green: 115/255, blue: 53/255), lineWidth: 3) // Darker green stroke
                )
                .overlay(
                    Circle()
                        .stroke(Color(red: 136/255, green: 219/255, blue: 125/255), lineWidth: 9) // Lighter green stroke
                )
                .shadow(color: Color(red: 0/255, green: 100/255, blue: 0/255).opacity(0.5), radius: 9, x: 0, y: 9)
                .shadow(color: .black.opacity(0.3), radius: 2.5, x: 0, y: 2.5)
                .opacity(gameModelView.isHoldingButton ? 0.7 : 1.0)
                .offset(joystickPosition)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !gameModelView.isHoldingButton {
                                withAnimation {
                                    gameModelView.isHoldingButton = true
                                }
                                print("Joystick pressed down")
                            }

                            // Define the maximum distance the handle can move (radius)
                            let radius: CGFloat = 85 // Half of base circle's width
                            let translation = value.translation
                            let distance = min(sqrt(translation.width * translation.width + translation.height * translation.height), radius)

                            // Calculate angle
                            let angle = atan2(translation.height, translation.width)

                            // Update joystick position
                            joystickPosition = CGSize(
                                width: distance * cos(angle),
                                height: distance * sin(angle)
                            )

                            // Update magnitude and angle in gameModelView
                            gameModelView.joystickMagnitude = distance/radius // Normalize if needed
                            gameModelView.joystickAngle = Angle(radians: Double(angle))
                        }
                        .onEnded { _ in
                            withAnimation {
                                gameModelView.isHoldingButton = false
                                joystickPosition = .zero
                                gameModelView.joystickMagnitude = 0
                                gameModelView.joystickAngle = Angle(degrees: 0)
                            }
                            print("Joystick released")
                        }
                )
        }
    }

    private var selectionButton2: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.5)) {
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
        // .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        // .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        .padding(.bottom, 50)
    }
}

// Assuming RealityViewWithTap and AnswerButton are defined elsewhere in your project.
// Ensure that all necessary imports and environment objects are correctly set up.

import RealityKit
import RealityKitContent
import SwiftUI

struct RealityViewWithTap: View {
    // @Binding var showQuestion: Bool
    @EnvironmentObject var gameModelView: GameModelView

    var body: some View {
        RealityView { content in
            // 1) Create an anchor for the ball (e.g. a "world origin" anchor).
            content.add(spaceOriginBall)

            // Check if a ball already exists
            let ballExists = spaceOriginBall.children.contains { entity in
                entity.name == "ball"
            }

            // Only create and add a new ball if one doesn't exist
            if !ballExists {
                // 2) Create a ball entity programmatically.
                let ball = ModelEntity(
                    mesh: .generateSphere(radius: 0.6),
                    materials: [SimpleMaterial(color: .red, isMetallic: true)]
                )
                ball.name = "ball"
                ball.position = [0, 0, 0]
                // Add collisions so that taps can hit-test the ball.
                ball.generateCollisionShapes(recursive: true)
                ball.components.set(InputTargetComponent())

                // 3) Attach the tap component so it can receive tap events.
                ball.components.set(TapComponent())

                ball.components.set(MoveComponent())
                // Add a camera entity
                let camera = PerspectiveCamera()
                camera.position = [0, 0, 5] // Position relative to the character

                // Parent the camera to the character
                ball.addChild(camera)

                // 4) Add the ball to the anchor.
                spaceOriginBall.addChild(ball)
            }

            // Optionally add environment models:
            if let meadowModel = entityModelDictionary["meadow"] {
                spaceOriginBall.addChild(meadowModel.entity)
            }
            if let waterModel = entityModelDictionary["water"] {
                spaceOriginBall.addChild(waterModel.entity)
            }

            print("End of ball realityview")
        }
        update: { content in
            // This block runs each frame on the SwiftUI side.
            // We can check if the ball was tapped and, if so, show the question.
            // print("Entered update block in realityviewwithtap")
            // 1) Find the ball (by name).
            if let ball = content.entities.first(where: { $0.name == "ball" }),

               var tapComponent = ball.components[TapComponent.self],
               var moveComponent = ball.components[MoveComponent.self]
            {
                // print("Debug: Ball found")

                // 2) If the ball was tapped, show the question:
                if tapComponent.didTap {
                    // print("RealityViewWithTap detected tap on ball. Updating showQuestion to true.")
                    gameModelView.showQuestion = true
                    // If you want the question only to appear once per tap,
                    // reset didTap so it doesn’t show again next frame.
                    tapComponent.didTap = false
                    ball.components[TapComponent.self] = tapComponent
                    // print("Value of didtap: \(tapComponent.didTap)")
                    ball.components.remove(TapComponent.self)
                }
            }
        }
        // 6) Install the tap gesture in SwiftUI so we can receive touches.
        .installTapGesture()
    }
}

// A reusable AnswerButton view for multiple-choice options
struct AnswerButton: View {
    let option: Int
    @Binding var selectedOption: Int?
    var body: some View {
        Button(action: {
            // The parent view handles hiding the question box after selection
            selectedOption = option
        }) {
            Text("\(option)")
                .foregroundColor(.white)
        }
        .buttonStyle(CustomButtonStyle())
        .overlay(
            selectedOption == option
                ? RoundedRectangle(cornerRadius: 8)
                .stroke(option == 4 ? Color.green : Color.red, lineWidth: 4)
                : nil
        )
    }
}
