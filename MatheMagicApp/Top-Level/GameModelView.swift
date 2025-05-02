import Combine
import Foundation
import RealityKit
import SwiftUI
import AnimLib
import joystickController


class GameModelView: ObservableObject, JoystickDataProvider {
    static let shared = GameModelView()
    let gameModel: GameModel

    @Published var isPaused: Bool = false {
        didSet {
            Task { await updateIsPausedInComponents() }
        }
    }

    @Published var isFinished: Bool = false
    @Published var currentState: GameScreenState = .start
    
    @Published var assetsLoaded: Bool = false // property to track asset loading
    @Published var score: Int = 0
    @Published var clockTime: Double = 0

    @Published var showQuestion: Bool = false
    @Published var isHoldingButton: Bool = false
    
    // MARK: Joystick data
    @Published var joystickMagnitude: CGFloat = 0
    @Published var joystickAngle: Angle = .degrees(0)
    @Published var joystickIsTouching = false
    var cameraYaw: Angle { camera.cameraYaw }

    /// Generic gesture state accessible to various systems.
    @Published var isDragging: Bool = false
    @Published var rawDragTranslation: CGSize? = nil

    @Published var isPinching: Bool = false
    @Published var rawPinchScale: CGFloat = 1.0
    var initialPinchScale: CGFloat = 1.0 // capture starting scale

    @Published var camera: CameraState = .init()

    private var timer: Timer?
    private var startDate: Date?

    private init() {
        self.gameModel = GameModel()
        Task {
            await self.gameModel.initialize()
        }
        startTimer()
    }

    // update animationComponent with isPaused
    var rootEntity: Entity? {
        didSet {
            Task { await updateIsPausedInComponents() }
        }
    } // need to pull the scene it is in

    @MainActor
    func updateIsPausedInComponents() {}

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { _ in
            Task {
                let state = await self.gameModel.getGameScreenState()
                let score = await self.gameModel.score
                await MainActor.run {
                    self.currentState = state
                    self.score = score
                    if let start = self.startDate {
                        self.clockTime = Date().timeIntervalSince(start)
                    }
                }
            }
        }
    }

    func togglePause() {
        isPaused.toggle()
        Task {
            await gameModel.setPaused(isPaused)
        }
    }

    func setFinished(_ finished: Bool) {
        isFinished = finished
        Task {
            await gameModel.setFinished(finished)
        }
    }

    func play() {
        // When starting a new game, record the start time.
        startDate = Date()
        Task {
            await gameModel.play()
        }
    }

    func lobby() {
        // Record the start time if not already set
        if startDate == nil {
            startDate = Date()
        }
        Task {
            await gameModel.lobby()
        }
    }

    func selection() {
        if startDate == nil {
            startDate = Date()
        }
        Task {
            await gameModel.selection()
        }
    }

    func ball() {
        Task {
            await gameModel.ball()
        }
    }

    func reset() {
        // Reset the start time to now.
        startDate = Date()
        Task {
            await gameModel.reset()
        }
    }
}
