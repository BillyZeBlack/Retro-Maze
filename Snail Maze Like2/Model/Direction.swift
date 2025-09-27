//
//  Direction.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 22/09/2025.
//

import Foundation

public enum Direction: Int, CaseIterable {
    case up = 0, right = 1, down = 2, left = 3
    
    public var dx: Int {
        switch self {
        case .left: return -1
        case .right: return 1
        case .up, .down: return 0
        }
    }
    
    public var dy: Int {
        switch self {
        case .up: return -1
        case .down: return 1
        case .left, .right: return 0
        }
    }
    
    public var wallIndex: Int { rawValue }
}
