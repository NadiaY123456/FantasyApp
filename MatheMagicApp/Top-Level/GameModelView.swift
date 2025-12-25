import AnimLib
import AssetLib
import Combine
import CoreLib
import Foundation
import joystickController
import RealityKit
import SwiftUI

class GameModelView: ObservableObject, JoystickDataProvider {
    // MARK: - Animation Debug HUD (overlay)

    @Published var showAnimationDebugHUD: Bool = false {
        didSet {
            // Enable/disable emission at the source (AnimLib), and clear history when turning ON.
            AnimationDebugBus.shared.setEnabled(showAnimationDebugHUD, resetHistory: showAnimationDebugHUD)
        }
    }

    @Published var animationDebugHUDCards: [AnimationDebugCard] = []

    private var animationDebugHUDCancellables = Set<AnyCancellable>()

    lazy var gameModel: GameModel = .init(gameModelView: self, teraStore: teraStore)

    let teraStore: TeraModelDictionaryActor

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

    // MARK: - RealityView text input (future AI prompt pipeline)
    @Published var realityTextInput: RealityTextInputState = .init()

    @Published var isUserTextInputFocused: Bool = false

    // MARK: - AI (AILib contract pipeline)
    @Published var aiDebug: AIDebugState = .init()

    private let aiPipeline = MatheMagicAIEventPipeline()
    private var aiTask: Task<Void, Never>?
    private var aiActiveEventID: UUID?

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

    init(teraStore: TeraModelDictionaryActor) {
        self.teraStore = teraStore
        Task { await gameModel.initialize() }

        setupAnimationDebugHUDSubscription()
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

    func toggleAnimationDebugHUD() {
        showAnimationDebugHUD.toggle()
    }

    @MainActor
    func handleSubmittedRealityText(_ event: UserTextInputEvent) {
        AppLogger.shared.info("📝 Captured user text input (\(event.source.rawValue)): \(event.text)")

        // Keep existing gameplay/event flow
        Task { await gameModel.enqueueUserTextInput(event) }

        // NEW: AI pipeline (AILib contract -> Ollama -> structured response)
        runAIClassification(for: event)
    }

    // MARK: - AI (AILib)

    @MainActor
    private func runAIClassification(for event: UserTextInputEvent) {
        // Cancel in-flight request (latest input wins)
        aiTask?.cancel()

        aiActiveEventID = event.id
        aiDebug.start(eventText: event.text)

        let eventID = event.id
        let eventText = event.text

        aiTask = Task { [weak self] in
            guard let self else { return }

            do {
                let result = try await self.aiPipeline.run(eventText: eventText)
                guard !Task.isCancelled, self.aiActiveEventID == eventID else { return }
                self.aiDebug.setSuccess(result)
            } catch is CancellationError {
                guard self.aiActiveEventID == eventID else { return }
                self.aiDebug.setCancelled()
            } catch {
                guard !Task.isCancelled, self.aiActiveEventID == eventID else { return }
                self.aiDebug.setFailure(error)
            }
        }
    }

    private func setupAnimationDebugHUDSubscription() {
        AnimationDebugBus.shared.events
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .reset:
                    self.animationDebugHUDCards.removeAll()

                case .card(let card):
                    self.animationDebugHUDCards.append(card)
                    if self.animationDebugHUDCards.count > 3 {
                        self.animationDebugHUDCards.removeFirst(self.animationDebugHUDCards.count - 3)
                    }
                }
            }
            .store(in: &animationDebugHUDCancellables)
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
        startDate = Date()
        Task {
            await gameModel.reset()
        }
    }

    deinit {
        aiTask?.cancel()
    }
}
