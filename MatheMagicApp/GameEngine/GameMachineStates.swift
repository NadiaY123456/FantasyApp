import GameplayKit
import RealityKit
//import OrderedCollections


// FOR PLAY/PAUSED/FINISHED/LOAD GAME MACHINE

class LoadState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        print("Entered Loading State")

        Task { @MainActor in
            
            await preLoadAssetsDict()
            setupEntities()
            
            //clearFileContent(at: dataExportJsonPath) // for debug purposes TODO: drop when disable dataExport
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is ReadyToStartState.Type
    }
}

class ReadyToStartState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        print("Entered Ready To Start State")
        print("Assets are loaded and gameModel initilize() is completed")
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is LobbyState.Type
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
        print("Entered Play State")

        playData.score += 10
        print("Current score is \(playData.score) should be 10")
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is FinishedState.Type || stateClass is PausedState.Type
    }
}

class LobbyState: GKState {
//    weak var playData: PlayData?
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        print("Entered Lobby State")
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is SelectionState.Type || stateClass is BallState.Type
    }
}

class SelectionState: GKState {
//    weak var playData: PlayData?
    

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        print("Entered Selection State")
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is FinishedState.Type
    }
}

class BallState: GKState {
//    weak var playData: PlayData?
    

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        print("Entered Ball State")
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is FinishedState.Type
    }
}

class PausedState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        print("Entered Finished State")
        // Handle game finish logic
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is PlayState.Type
    }
}

class FinishedState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        print("Entered Finished State")
        // Handle game finish logic
    }
}
