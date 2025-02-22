import GameplayKit
import RealityKit
import CoreLib
//import OrderedCollections


// FOR PLAY/PAUSED/FINISHED/LOAD GAME MACHINE

class LoadState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        AppLogger.shared.info("Entered Loading State")

        Task { @MainActor in
            // Start timing
            let startTime = Date()
            
            // Perform asset loading
            await preLoadAssetsDict()
            
            // Calculate elapsed time
            let elapsedTime = Date().timeIntervalSince(startTime)
            AppLogger.shared.info("Asset loading completed in \(elapsedTime) seconds")
            
//            // Store the elapsed time in GameModelView if needed
//            GameModelView.shared.clockTime = elapsedTime
            
            // Continue with remaining setup
            setupEntities()
            
            //clearFileContent(at: dataExportJsonPath) // for debug purposes TODO: drop when disable dataExport
            GameModelView.shared.assetsLoaded = true
            GameModelView.shared.currentState = .start  // or a dedicated ready state
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is ReadyToStartState.Type
    }
}


class ReadyToStartState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        AppLogger.shared.info("Entered Ready To Start State")
        AppLogger.shared.info("Assets are loaded and gameModel initilize() is completed")
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
//        return stateClass is LobbyState.Type
        return stateClass is SelectionState.Type || stateClass is LobbyState.Type // DEBUG
    }
}

class PlayState: GKState {
//    weak var playData: PlayData?
    
    var playData: PlayData
    init(playData: PlayData) {
            self.playData = playData
        }

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        AppLogger.shared.info("Entered Play State")

        playData.score += 10
        AppLogger.shared.info("Current score is \(playData.score) should be 10")
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is FinishedState.Type || stateClass is PausedState.Type
    }
}

class LobbyState: GKState {
//    weak var playData: PlayData?
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        AppLogger.shared.info("Entered Lobby State")
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is SelectionState.Type || stateClass is BallState.Type
    }
}

class SelectionState: GKState {
//    weak var playData: PlayData?
    

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        AppLogger.shared.info("Entered Selection State")
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is FinishedState.Type || stateClass is LobbyState.Type
    }

}

class BallState: GKState {
//    weak var playData: PlayData?
    

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        AppLogger.shared.info("Entered Ball State")
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is FinishedState.Type || stateClass is LobbyState.Type
    }

}

class PausedState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        AppLogger.shared.info("Entered Finished State")
        // Handle game finish logic
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is PlayState.Type
    }
}

class FinishedState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        AppLogger.shared.info("Entered Finished State")
        // Handle game finish logic
    }
}
