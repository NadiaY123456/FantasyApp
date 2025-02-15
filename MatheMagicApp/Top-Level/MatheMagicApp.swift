import RealityKit
import SwiftUI
import AnimLib
import CoreLib


@main
struct FantasyAppGithubApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var gameModelView = GameModelView.shared
    var playData = PlayData()
//    var settings = Settings()

    init() {
        
        // MARK: COMPONENTS
        MoveComponent.registerComponent()
        TapComponent.registerComponent()
        CameraRotationComponent.registerComponent()
        
        //coreLib
        DataCenterComponent.registerComponent()
        
        //animLib
        EventComponent.registerComponent()
        BrainComponent.registerComponent()
        TravelComponent.registerComponent()
        CustomAnimationComponent.registerComponent()
        AnimationComponent.registerComponent()
        
        // MARK: SYSTEMS
        MoveSystem.registerSystem()
        TapSystem.registerSystem()
        CameraRotationSystem.registerSystem()
        
        //coreLib
        DataCenterSystem.registerSystem()
        
        //animLib
        EventSystem.registerSystem()
        BrainSystem.registerSystem()
        TravelSystem.registerSystem()
        CustomAnimationSystem.registerSystem()
        AnimationSystem.registerSystem()
        
        
        

        
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
