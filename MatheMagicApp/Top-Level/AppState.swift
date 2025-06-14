// Home -> HappyBeam

// This is not Home screen, but whatever game environment user is in, depending on the game state. The actual view is defined by the switch statements.
// So when the experience starts, it will show the start screen, then progress to the Play and when finishes goes to Score

import RealityKit
//import RealityKitContent
import SwiftUI

struct AppState: View {
    unowned let gameModelView: GameModelView

        init(gameModelView: GameModelView) {
            self.gameModelView = gameModelView
        }

    @State private var timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        let gameState = gameModelView.currentState
        VStack {
            Spacer()
            Group {
                switch gameState {
                case .start:
                    Start()
                case .loading:
                    ProgressView("Loading assets...") //TODO: check if this will work
                case .play:
                    Play()
                case .gameOver:
                    GameOver()
                case .lobby:
                    Lobby()
                case .selection:
                    Selection()
                case .ball:
                    BallView()
                }
            }
        }
        .onReceive(timer) { _ in
//            pr(gameModel.appStateMachine.currentState, variableName: "appStateMachine.currentState:")
            if gameModelView.currentState == .play {
                Task {
                }

                if !gameModelView.isPaused {
//                    spawnTask(enityTemplateIndex: 2)
                }
            }
        }
    }
}


