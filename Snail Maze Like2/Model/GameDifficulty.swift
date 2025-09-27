//
//  GameDifficulty.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 22/09/2025.
//

import Foundation

public enum GameDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy", normal = "Normal", hard = "Hard"
    public var id: String { rawValue }
    public var difficultyBoost: Double { switch self { case .easy: 1.35; case .normal: 1.20; case .hard: 1.10 } }
    public var buffer: Double { switch self { case .easy: 8; case .normal: 5; case .hard: 3 } }
}
