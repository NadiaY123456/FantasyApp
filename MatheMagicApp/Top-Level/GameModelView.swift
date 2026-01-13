import AnimLib
import AssetLib
import Combine
import CoreLib
import Foundation
import joystickController
import RealityKit
import SwiftUI

class GameModelView: ObservableObject, JoystickDataProvider, AIIdleAnimationSuggestionProvider {
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

    // MARK: - Character Dialogue Bubble
    @Published var characterDialogue: CharacterDialogueState = .init()

    private let aiPipeline = MatheMagicAIEventPipeline()
    private let aiCharacterDialoguePipeline = MatheMagicAICharacterDialoguePipeline()

    private var aiTask: Task<Void, Never>?
    private var aiDialogueTask: Task<Void, Never>?
    private var aiActiveEventID: UUID?

    private var dialogueHideTask: Task<Void, Never>?

    private var pendingAIIdleAnimationSuggestion: String?

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

    func consumeAIIdleAnimationSuggestion() -> String? {
        let v = pendingAIIdleAnimationSuggestion
        pendingAIIdleAnimationSuggestion = nil
        return v
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
        aiDialogueTask?.cancel()

        aiActiveEventID = event.id
        aiDebug.start(eventText: event.text)

        // Prevent an older pending suggestion from applying after a newer prompt is submitted.
        pendingAIIdleAnimationSuggestion = nil
        clearCharacterDialogue()

        let eventID = event.id
        let eventText = event.text

        // Character dialogue bubble (separate from the existing classification pipeline)
        aiDialogueTask = Task { [weak self] in
            guard let self else { return }

            do {
                let speech = try await self.aiCharacterDialoguePipeline.run(eventText: eventText)
                try Task.checkCancellation()

                await MainActor.run {
                    guard !Task.isCancelled, self.aiActiveEventID == eventID else { return }
                    self.showCharacterDialogue(speech)
                }
            } catch is CancellationError {
                // no-op
            } catch {
                AppLogger.shared.error("AI Dialogue: FAILED eventID=\(eventID) error=\(String(describing: error))")
            }
        }

        aiTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let result = try await self.aiPipeline.run(eventText: eventText)
                guard !Task.isCancelled, self.aiActiveEventID == eventID else { return }

                self.aiDebug.setSuccess(result)

                self.pendingAIIdleAnimationSuggestion = FlashAIIdleEmoteCatalog.normalizedSuggestion(
                    from: result.values[FlashAIIdleEmoteCatalog.aiContractFieldKey]
                )
            } catch is CancellationError {
                guard self.aiActiveEventID == eventID else { return }
                self.aiDebug.setCancelled()

                AppLogger.shared.info("AI: cancelled eventID=\(eventID)")
            } catch {
                guard !Task.isCancelled, self.aiActiveEventID == eventID else { return }
                self.aiDebug.setFailure(error)

                // Ensure it shows in Xcode console.
                let err = String(describing: error)
                AppLogger.shared.error("AI: FAILED eventID=\(eventID) error=\(err)")
                print("AI: FAILED eventID=\(eventID) error=\(err)")
            }
        }
    }

    // MARK: - Character Dialogue Bubble helpers

    @MainActor
    private func showCharacterDialogue(_ text: String, durationSeconds: TimeInterval = 15) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard durationSeconds > 0 else { return }

        dialogueHideTask?.cancel()

        let newState = CharacterDialogueState(id: UUID(), text: trimmed, isVisible: true)
        characterDialogue = newState

        let shownID = newState.id
        dialogueHideTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(nanoseconds: UInt64(durationSeconds * 1_000_000_000))
            } catch {
                return
            }

            guard self.characterDialogue.id == shownID else { return }
            self.characterDialogue = .init()
        }
    }

    @MainActor
    private func clearCharacterDialogue() {
        dialogueHideTask?.cancel()
        dialogueHideTask = nil
        characterDialogue = .init()
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
                    if let last = self.animationDebugHUDCards.last,
                       last.kind == card.kind,
                       last.title == card.title
                    {
                        // Same animation/transition: update in place (preserve id so SwiftUI doesn't treat it as a new card).
                        let updated = AnimationDebugCard(
                            id: last.id,
                            gameTimeSeconds: card.gameTimeSeconds,
                            characterName: card.characterName,
                            kind: card.kind,
                            title: card.title,
                            subtitle: card.subtitle,
                            details: card.details
                        )
                        self.animationDebugHUDCards[self.animationDebugHUDCards.count - 1] = updated
                    } else {
                        self.animationDebugHUDCards.append(card)
                        if self.animationDebugHUDCards.count > 3 {
                            self.animationDebugHUDCards.removeFirst(self.animationDebugHUDCards.count - 3)
                        }
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
        aiDialogueTask?.cancel()
        dialogueHideTask?.cancel()
    }
}
