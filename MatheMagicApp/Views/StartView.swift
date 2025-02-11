//import SwiftUI
//
//struct ContentView: View {
//    @State private var isPressed: Bool = false
//    @State private var currentScreen: AppScreen = .content // Current screen state
//    
//    var body: some View {
//        ZStack {
//            // ContentView's Background Image
//            Image("BackgroundImage") // Ensure this image exists in Assets.xcassets
//                .resizable()
//                .scaledToFill()
//                .edgesIgnoringSafeArea(.all)
//            
//            // Main Content VStack
//            VStack {
//                Spacer()
//                
//                
//                
//                Spacer()
//                    .frame(height: 120)
//            }
//            .padding()
//            
//            // Conditional Presentation of BlankView
//            if currentScreen == .blank {
//                BlankView(currentScreen: $currentScreen)
//                    .transition(.opacity) // Fade-in transition
//                    .zIndex(1) // Ensure it overlays above other views
//            }
//            
//            // Conditional Presentation of RealityView
//            if currentScreen == .reality {
//                CharacterSelectionView()
//                    .transition(.opacity) // Fade-in transition
//                    .zIndex(1) // Ensure it overlays above other views
//            }
//            
//            // Conditional Presentation of BallView
//            if currentScreen == .ballView {
//                BallView()
//                    .transition(.opacity) // Fade-in transition
//                    .zIndex(1) // Ensure it overlays above other views
//            }
//            
//        }
//        
//    }
//    
//    private var playButton: some View {
//        
//        // Play Button
//        Button(action: {
//            withAnimation(.easeInOut(duration: 0.5)) { // Animate the transition
//                //currentScreen = .blank // Navigate to BlankView
//                gameModelView.play()
//                gameModelView.timeLeft = GameModel.gameTime
//            }
//        }) {
//            Text("Begin")
//                .font(.custom("TimesNewRomanPS-BoldMT", size: 60)) // Bold "Times New Roman" font
//                .foregroundColor(.white)
//                .padding()
//                .frame(width: 300, height: 120)
//                .background(Color(red: 81/255, green: 156/255, blue: 72/255))
//                .cornerRadius(30) // Consistent corner radius
//                .overlay(
//                    RoundedRectangle(cornerRadius: 30) // Green border
//                        .stroke(Color(red: 60/255, green: 115/255, blue: 53/255), lineWidth: 2)
//                )
//                .overlay(
//                    RoundedRectangle(cornerRadius: 30) // Dark Green border
//                        .stroke(Color(red: 136/255, green: 219/255, blue: 125/255), lineWidth: 6)
//                )
//                .shadow(color: Color(red: 0/255, green: 100/255, blue: 0/255).opacity(0.5), radius: 10, x: 0, y: 10) // Dark Green Shadow
//                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5) // Additional subtle shadow
//                .scaleEffect(isPressed ? 0.95 : 1.0) // Scales down when pressed
//                .animation(.easeInOut(duration: 0.2), value: isPressed) // Smooth animation
//        }
//        .scaleEffect(isPressed ? 0.95 : 1.0) // Retain scaling
//        .disabled(gameModelView.currentState != .start)
//        .animation(.easeInOut(duration: 0.2), value: isPressed) // Smooth animation
//        .onLongPressGesture(minimumDuration: 0.0, pressing: { pressing in
//            withAnimation {
//                isPressed = pressing
//            }
//        }, perform: {})
//        
//    }
//    
//}
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
