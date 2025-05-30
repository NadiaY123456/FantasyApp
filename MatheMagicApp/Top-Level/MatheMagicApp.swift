// MatheMagicApp.swift

import AnimLib
import AssetLib
import CoreLib
import RealityKit
import SwiftUI

@main
struct FantasyAppGithubApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // ─────────────  SINGLETONS FOR THE WHOLE APP  ─────────────
    private let teraStore: TeraModelDictionaryActor
    @StateObject private var gameModelView: GameModelView
//    var playData = PlayData()

    // ───────────────────────── init ───────────────────────────
    init() {
        // 1️⃣  Build the *one* store and view-model
        let store = TeraModelDictionaryActor()
        let gmv = GameModelView(teraStore: store)

        // 2️⃣  Assign them to the stored properties
        self.teraStore = store
        _gameModelView = StateObject(wrappedValue: gmv)

        // 3️⃣  Register components & systems  (unchanged)
        MoveComponent.registerComponent()
        TapComponent.registerComponent()
        CameraRotationComponent.registerComponent()

        MoveSystem.registerSystem()
        TapSystem.registerSystem()
        CameraRotationSystem.registerSystem()

        // CoreLib
        DataCenterComponent.registerComponent()
        DataCenterSystem.registerSystem()

        // AnimLib
        EventComponent.registerComponent()
        BrainComponent.registerComponent()
        AnimationComponent.registerComponent()
        TravelComponent.registerComponent()

        EventSystem.registerSystem()
        BrainSystem.registerSystem()
        AnimationSystem.registerSystem()
        TravelSystem.registerSystem()

        // 4️⃣  Hook AppLogger to the *same* view-model
        AppLogger.shared.clockTimeProvider = { [weak gmv] in
            gmv?.clockTime ?? 0
        }

        // 🆕 give every system the same reference
        MoveSystem.gameModelView = gmv
        TapSystem.gameModelView = gmv
        CameraRotationSystem.gameModelView = gmv
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameModelView)
//                .environmentObject(playData)
                .environment(\.teraStore, teraStore)
//                .onAppear {
//                    guard let windowScreen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
//                        return
//                    }
//                    windowScreen.requestGeometryUpdate(.Vision(resizingRestrictions: UIWindowScene.ResizingRestrictions.none))
//                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: UIApplication) -> Bool {
        return true
    }
}

// @MainActor
// enum ThrowGestureModelContainer {
//    private(set) static var throwGestureModel = ThrowGestureModel()
// }
