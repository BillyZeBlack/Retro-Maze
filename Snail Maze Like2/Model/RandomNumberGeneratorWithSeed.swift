//
//  RandomNumberGeneratorWithSeed.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 22/09/2025.
//

import Foundation

struct RandomNumberGeneratorWithSeed: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64?) {
        self.state = seed ?? UInt64.random(in: 0...UInt64.max)
    }
    
    mutating func next() -> UInt64 {
        state = (state &* 6364136223846793005) &+ 1442695040888963407
        return state
    }
}
