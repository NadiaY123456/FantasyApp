//
//  AIEndpointConfig.swift
//  MatheMagicApp
//

import Foundation

struct AIEndpointConfig: Sendable, Equatable {
    var baseURLString: String
    var modelName: String
    var timeout: TimeInterval

    static var current: AIEndpointConfig {
        .init(
            baseURLString: MatheMagicAIConfig.baseURLString,
            modelName: MatheMagicAIConfig.modelName,
            timeout: MatheMagicAIConfig.timeout
        )
    }
}
