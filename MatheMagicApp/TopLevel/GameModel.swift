import AVKit
import Combine
import GameplayKit
import RealityKit
//import RealityKitContent
import SwiftUI

actor GameModel {
    let playData = PlayData()
    let appStateMachine: GKStateMachine

    private var _isPaused = false
    private var _isFinished = false {
        didSet {
            if _isFinished == true {
                Task { await clear() } 
            }
        }
    }

    static let gameTime = 100
    var timeLeft = gameTime
    var score = 0

    func isPaused() -> Bool {
        return _isPaused
    }

    func setPaused(_ paused: Bool) {
        _isPaused = paused
    }

    func isFinished() -> Bool {
        return _isFinished
    }

    func setFinished(_ finished: Bool) {
        _isFinished = finished
    }

    /// Removes 3D content when the game is over.
    @MainActor // Dispatch the clear() method to the main actor since UI updates should occur on the main thread.
    func clear() {
        spaceOrigin.children.removeAll()
    }

    /// Resets game state information.
    func reset() {
        _isPaused = false
        _isFinished = false
        timeLeft = GameModel.gameTime
        score = 0
        Task { await clear() }
    }

    /// Preload assets when the app launches to avoid pop-in during the game.
    init() {
        appStateMachine = GKStateMachine(states: [
            LoadState(),
            ReadyToStartState(),
            PlayState(playData: playData),
            PausedState(),
            LobbyState(),
            BallState(),
            SelectionState(),
            FinishedState()
        ])
    }

    func initialize() {
        load()
        readyToStart()
    }

    private var _gameScreenState: GameScreenState = .start
    func getGameScreenState() -> GameScreenState {
        return _gameScreenState
    }

    // Update _gameScreenState whenever the state changes
    func load() {
        appStateMachine.enter(LoadState.self)
        if !(appStateMachine.currentState is LoadState) {
            print("Error: Failed to transition to Load State")
        }
        _gameScreenState = .loading//TODO: should be load once I have load view. Also, realityview supports progressiveview that shows up before content and update. search documentation.
    }

    func readyToStart() {
        appStateMachine.enter(ReadyToStartState.self)
        if !(appStateMachine.currentState is ReadyToStartState) {
            print("Error: Failed to transition to Ready To Start State")
        }
        _gameScreenState = .start

    }

    func play() {
        appStateMachine.enter(PlayState.self)
        if !(appStateMachine.currentState is PlayState) {
            print("Error: Failed to transition to Play State")
        }
        _gameScreenState = .play

    }
    
    func lobby() {
        appStateMachine.enter(LobbyState.self)
        if !(appStateMachine.currentState is LobbyState) {
            print("Error: Failed to transition to Lobby State")
        }
        _gameScreenState = .lobby

    }
    
    func selection() {
        appStateMachine.enter(SelectionState.self)
        if !(appStateMachine.currentState is SelectionState) {
            print("Error: Failed to transition to Selection State")
        }
        _gameScreenState = .selection

    }
    
    func ball() {
        appStateMachine.enter(BallState.self)
        if !(appStateMachine.currentState is BallState) {
            print("Error: Failed to transition to Ball State")
        }
        _gameScreenState = .ball

    }
    
    
}

enum GameScreenState: Sendable {
    case start
    case loading
    case play
    case gameOver
    case lobby
    case selection
    case ball
}
