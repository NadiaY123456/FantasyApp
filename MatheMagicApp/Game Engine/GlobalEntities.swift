//
//  GlobalEntities.swift
//  FantasyAppGithub
//
//  Created by Nadia Yilmaz on 12/25/24.
//
import RealityKit

// The root entity for entities placed during the game.
let spaceOrigin = Entity()

let spaceOriginBall = Entity()

func setupEntities() {
    // The root entity for entities placed during the game.
    
    spaceOrigin.name = "SpaceOrigin"
    spaceOrigin.position = SIMD3<Float>(0, 0, 0)
    
    spaceOriginBall.name = "SpaceOriginBall"
    spaceOriginBall.position = SIMD3<Float>(0, 0, 0)
    
    
}
