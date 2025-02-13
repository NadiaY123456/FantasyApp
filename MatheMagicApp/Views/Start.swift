import SwiftUI

struct Start: View {
    @ObservedObject var gameModelView = GameModelView.shared
    @State private var isPressed: Bool = false

    var body: some View {
        ZStack {
            // Background Image
            Image("BackgroundImage") // Ensure this image exists in Assets.xcassets
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer(minLength: 500) // Adjust top spacer as needed

                // Conditional Views based on game state
                if gameModelView.currentState == .start {
                    playButton
                } else if gameModelView.currentState == .loading {
                    ProgressView("Loading assets...")
                } else {
                    Text("Game is currently in progress or finished.")
                }

                Spacer(minLength: 100) // Adjust bottom spacer as needed
            }
            .padding(.horizontal, 150)
            .frame(width: 634, height: 499)
        }
    }

    // Play Button View
    private var playButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.5)) {
                gameModelView.lobby()
            }
        }) {
            Text("Begin")
                .font(.custom("TimesNewRomanPS-BoldMT", size: 60)) // Bold "Times New Roman" font
                .foregroundColor(.white)
                .padding()
                .frame(width: 300, height: 120)
                .background(Color(red: 81/255, green: 156/255, blue: 72/255))
                .cornerRadius(30)
                .overlay(
                    RoundedRectangle(cornerRadius: 30) // Green border
                        .stroke(Color(red: 60/255, green: 115/255, blue: 53/255), lineWidth: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30) // Dark Green border
                        .stroke(Color(red: 136/255, green: 219/255, blue: 125/255), lineWidth: 6)
                )
                .shadow(color: Color(red: 0/255, green: 100/255, blue: 0/255).opacity(0.5), radius: 10, x: 0, y: 10)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isPressed)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .disabled(gameModelView.currentState != .start)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.0, pressing: { pressing in
            withAnimation {
                isPressed = pressing
            }
        }, perform: {})
    }
}
