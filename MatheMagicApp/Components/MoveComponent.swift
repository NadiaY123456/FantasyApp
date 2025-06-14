//
//  TestComponent.swift
//  FantasyAppGithub
//
//  Created by Nadia Yilmaz on 12/28/24.
//
import RealityKit
import CoreLib

struct MoveComponent: RealityKit.Component {
    //public var isMoving: Bool = false
    var posx: Float = 0.0
    var posz: Float = 0.0
}

class MoveSystem: RealityKit.System {
    @MainActor private static let query = EntityQuery(where: .has(MoveComponent.self))
    static weak var gameModelView: GameModelView?


    required init(scene: RealityKit.Scene) {}

    static var dependencies: [SystemDependency] { [] }

    func update(context: SceneUpdateContext) {
        guard let gameModelView = Self.gameModelView else {
            AppLogger.shared.error("Error: GameModelView is not set for MoveSystem")
            return
        }
        // get the entities that have animation and motion component
        let characters = context.entities(matching: Self.query, updatingSystemWhen: .rendering)

        let deltaPos : Float = 0.03
        for character in characters {
            guard
                var moveComponent = character.components[MoveComponent.self]
            else { continue }
            var posx = moveComponent.posx
            var posz = moveComponent.posz
            if gameModelView.isHoldingButton {
                let xVar = deltaPos * Float(gameModelView.joystickMagnitude) * cos(Float(gameModelView.joystickAngle.radians))
                let zVar = deltaPos * Float(gameModelView.joystickMagnitude) * sin(Float(gameModelView.joystickAngle.radians))
                posx += xVar
                posz += zVar
                moveComponent.posx = posx
                moveComponent.posz = posz
                character.position = simd_float3(posx, 0, posz)
                character.components.set(moveComponent)
//                pos += deltaPos
//                moveComponent.pos = pos
//                character.position = simd_float3(pos, 0, 0)
//                character.components.set(moveComponent)
            }
        }
    }
}
