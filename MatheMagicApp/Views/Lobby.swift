import SwiftUI

struct Lobby: View {
    //@Binding var currentScreen: AppScreen // Binding to manage navigation
    //@Published var currentState: GameScreenState
    @State var playAnimation: Bool = false
    @EnvironmentObject var gameModelView: GameModelView

    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all) // Full-screen white background

            VStack {
                Spacer()

                Text("Welcome to the New Scene!")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    .padding()

                Spacer()
                
                if gameModelView.currentState == .lobby {
                    selectionButton1
                    selectionButton2
                } else {
                    Text("Error: Game is not in Lobby")
                }

                

            }
        }
        .transition(.opacity) // Fade-in transition
    }
    
    private var selectionButton1: some View {
        // Button to navigate to CharacterSelectionView
        
        Button(action: {
            withAnimation(.easeInOut(duration: 0.5)) { // Animate the transition
                spaceOrigin.isEnabled = true
                gameModelView.selection()
                playAnimation = true
            }
        }) {
            Text("Go to Reality")
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
        .scaleEffect(0.95) // Slightly smaller when pressed
        .animation(.easeInOut(duration: 0.2), value: playAnimation)
        .padding(.bottom, 20) // Adjust padding as needed

    }
    
    private var selectionButton2: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.5)) { // Animate the transition
                spaceOriginBall.isEnabled = true
                gameModelView.ball() // Navigate to BallView
                playAnimation = true
            }
        }) {
            Text("Go to Ball View")
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
        }
        .scaleEffect(0.95) // Slightly smaller when pressed
        .animation(.easeInOut(duration: 0.2), value: playAnimation)
        .padding(.bottom, 50) // Adjust padding as needed
        

    }
}
