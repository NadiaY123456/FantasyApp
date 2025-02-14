import Combine
import SwiftUI

// class PlayData: ObservableObject {
//    @Published var score = 0
// }

// You can also create a custom property wrapper that ensures thread safety. This wrapper would use synchronization mechanisms such as locks to protect access to the score.

@propertyWrapper
struct ThreadSafe<Value> {
    private var value: Value
    private let lock = NSLock()

    var wrappedValue: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        set {
            lock.lock()
            value = newValue
            lock.unlock()
        }
    }

    init(wrappedValue: Value) {
        self.value = wrappedValue
    }
}

class PlayData: ObservableObject {
    @ThreadSafe var score = 0
    @ThreadSafe var characterSpeed: SIMD2<Float>? // Length between 0 and 1.
    @ThreadSafe var jumpIndex: UInt = 0
}

// GAME ENGINE

//func spawnTask(enityTemplateIndex: Int) {
//    Task { @MainActor () in
//        do {
//            let spawn = try await entityTemplate[enityTemplateIndex].spawnEntity()
//            let _ = try await entityTemplate[enityTemplateIndex].animateSpawn(spawn: spawn)
//        }
//        catch {
//            AppLogger.shared.error("Error spawning from enityTemplate # \(enityTemplateIndex): \(entityTemplate[enityTemplateIndex].name)", error)
//        }
//    }
//}
