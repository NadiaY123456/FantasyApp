import SwiftUI
struct Start: View {
    @EnvironmentObject var gameModelView: GameModelView
    @State private var isPressed: Bool = false

    var body: some View {
        ZStack {
            // Background Image
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer(minLength: 500)

                if gameModelView.assetsLoaded && gameModelView.currentState == .start {
                    playButton
                } else {
                    LoadingIndicator()
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 150)
            .frame(width: 634, height: 499)
        }
    }

    private var playButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.5)) {
                gameModelView.selection() // Transition to the next state.
            }
        }) {
            Text("Begin")
                .font(.custom("TimesNewRomanPS-BoldMT", size: 60))
                .foregroundColor(.white)
                .padding()
                .frame(width: 300, height: 120)
                .background(Color(red: 81/255, green: 156/255, blue: 72/255))
                .cornerRadius(30)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color(red: 60/255, green: 115/255, blue: 53/255), lineWidth: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color(red: 136/255, green: 219/255, blue: 125/255), lineWidth: 6)
                )
                .shadow(color: Color(red: 0/255, green: 100/255, blue: 0/255).opacity(0.5), radius: 10, x: 0, y: 10)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isPressed)
        }
        .disabled(!gameModelView.assetsLoaded)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.0, pressing: { pressing in
            withAnimation {
                isPressed = pressing
            }
        }, perform: {})
    }
}

import SwiftUI

struct LoadingIndicator: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Base rectangle with your button style
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(red: 81/255, green: 156/255, blue: 72/255))
                .frame(width: 400, height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color(red: 60/255, green: 115/255, blue: 53/255), lineWidth: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color(red: 136/255, green: 219/255, blue: 125/255), lineWidth: 6)
                )
                .shadow(color: Color(red: 0/255, green: 100/255, blue: 0/255).opacity(0.5), radius: 10, x: 0, y: 10)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                .clipped()
            
            // Moving highlight shade that runs through the bar
            GeometryReader { geometry in
                let barWidth = geometry.size.width
                let gradientWidth: CGFloat = 100  // Width of the highlight

                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.4),
                                Color.white.opacity(0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: gradientWidth, height: geometry.size.height)
                    .offset(x: animate ? barWidth : -gradientWidth)
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: 1.5)
                                .repeatForever(autoreverses: false)
                        ) {
                            animate = true
                        }
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 30))
            
            // Centered loading text
            Text("Loading assets...")
                .font(.custom("TimesNewRomanPS-BoldMT", size: 30))
                .foregroundColor(.white)
        }
    }
}
