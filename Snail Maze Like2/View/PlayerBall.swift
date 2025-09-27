//
//  PlayerBall.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 22/09/2025.
//

import SwiftUI

struct PlayerBall: View {
    let x: CGFloat
    let y: CGFloat
    let diameter: CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    private var ballColor: Color {
        colorScheme == .dark ? .yellow : .yellow
    }
    
    private var ballGlow: Color {
        colorScheme == .dark ? .yellow.opacity(0.6) : .yellow.opacity(0.3)
    }
    
    var body: some View {
        Circle()
            .fill(ballColor)
            .frame(width: diameter, height: diameter)
            .shadow(color: ballGlow, radius: diameter * 0.3)
            .position(x: x, y: y)
    }
}
