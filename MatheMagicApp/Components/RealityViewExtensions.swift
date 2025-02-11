///*
// See the LICENSE.txt file for this sample’s licensing information.
//
// Abstract:
// App-specific extension on RealityView.
// */
//
//import Foundation
//import RealityKit
//import SwiftUI
//
//// MARK: - RealityView Extensions
//
//extension RealityView {
//    /// Apply this to a `RealityView` to pass gestures on to the component code.
//    func installGestures() -> some View {
//        simultaneousGesture(tapGesture)
//        
//    }
//
//    /// Builds a drag gesture.
//    var tapGesture: some Gesture {
//        TapGesture()
//            .targetedToEntity(where: .has(GestureComponent.self)) // Targets entities with a GestureComponent
//            .useGestureComponent()
//    }
//}
//
//extension Gesture where Value == EntityTargetValue<TapGesture.Value> {
//    
//    /// Connects the gesture input to the `GestureComponent` code.
//    func useGestureComponent() -> some Gesture {
//        onChanged { value in
//            guard var gestureComponent = value.entity.gestureComponent else { return }
//            
//            gestureComponent.onChanged(value: value)
//            
//            value.entity.components.set(gestureComponent)
//        }
//        .onEnded { value in
//            guard var gestureComponent = value.entity.gestureComponent else { return }
//            
//            gestureComponent.onEnded(value: value)
//            
//            value.entity.components.set(gestureComponent)
//        }
//    }
//}
//
//public extension Entity {
//    var gestureComponent: GestureComponent? {
//        get { components[GestureComponent.self] }
//        set { components[GestureComponent.self] = newValue }
//    }
//}
