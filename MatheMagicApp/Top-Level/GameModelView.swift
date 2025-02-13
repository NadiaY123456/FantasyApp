//
//  GameModelView.swift
//

import Combine
import Foundation
import RealityKit
import SwiftUI

// import RealityKitContent

class GameModelView: ObservableObject {
    static let shared = GameModelView()
    let gameModel: GameModel

    @Published var isPaused: Bool = false {
        didSet {
            Task { await updateIsPausedInComponents() }
        }
    }

    @Published var isFinished: Bool = false
    @Published var currentState: GameScreenState = .start
    @Published var score: Int = 0
    @Published var timeLeft: Int = 0
    @Published var showQuestion: Bool = false
    @Published var isHoldingButton: Bool = false
    @Published var joystickMagnitude: CGFloat = 0
    @Published var joystickAngle: Angle = .degrees(0)

    /// Generic gesture state accessible to various systems.
    @Published var isDragging: Bool = false
    @Published var rawDragTranslation: CGSize? = nil

    @Published var isPinching: Bool = false
    @Published var rawPinchScale: CGFloat = 1.0

    @Published var camera: CameraState =  CameraState()
    
    private var timer: Timer?

    private init() {
        self.gameModel = GameModel()
        Task {
            await self.gameModel.initialize()
        }
        startTimer()
    }

    // update animationComponent with isPauses
    var rootEntity: Entity? {
        didSet {
            Task { await updateIsPausedInComponents() }
        }
    } // need to pull the scene it is in

    @MainActor
    func updateIsPausedInComponents() {}

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task {
                let state = await self.gameModel.getGameScreenState()
                let score = await self.gameModel.score
                let timeLeft = await self.gameModel.timeLeft
                await MainActor.run {
                    self.currentState = state
                    self.score = score
                    self.timeLeft = timeLeft
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
        Task {
            await gameModel.play()
        }
    }

    func lobby() {
        Task {
            await gameModel.lobby()
        }
    }

    func selection() {
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
        Task {
            await gameModel.reset()
        }
    }
}
