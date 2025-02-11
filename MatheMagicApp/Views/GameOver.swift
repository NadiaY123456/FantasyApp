import SwiftUI

struct GameOver: View {
    @ObservedObject var gameModelView = GameModelView.shared


    var body: some View {
        VStack(spacing: 15) {
            Text("Great job!")
                .font(.system(size: 36, weight: .bold))
            Text("You hit \(gameModelView.score) aims.") 
                .multilineTextAlignment(.center)
                .font(.headline)
                .frame(width: 340)
                .padding(.bottom, 10)
            Group {
                Button {
                    playAgain()
                } label: {
                    Text("Play Again")
                        .frame(maxWidth: .infinity)
                }
                Button {
                    Task {
                        await goBackToStart()
                    }
                } label: {
                    Text("Back to Main Menu")
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(width: 220)
        }
        
        .padding(15)
        .frame(width: 634, height: 499)
    }
    
    func playAgain() {
        gameModelView.reset()
    }
    
    func goBackToStart() async {
        gameModelView.reset() 
    }
}
