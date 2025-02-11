import RealityKit
import SwiftUI


@main
struct FantasyAppGithubApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var gameModelView = GameModelView.shared
    var playData = PlayData()
//    var settings = Settings()

    init() {
        // SYSTEMS
        MoveSystem.registerSystem()
        TapSystem.registerSystem()

        // COMPONENTS
        MoveComponent.registerComponent()
        TapComponent.registerComponent()
        
        

        
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameModelView)
                .environmentObject(playData)
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
