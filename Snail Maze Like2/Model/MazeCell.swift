//
//  MazeCell.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 22/09/2025.
//

import Foundation

public struct MazeCell {
    public let x: Int
    public let y: Int
    public var walls: [Bool] = [true, true, true, true] // N, E, S, W
    public var visited: Bool = false
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}
