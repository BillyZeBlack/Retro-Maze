//
//  ItemView.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 25/09/2025.
//

import SwiftUI

struct ItemView: View {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var glow: Bool = false
    
    private var starColor: Color {
        colorScheme == .dark ? .yellow : .yellow
    }
    
    private var outlineColor: Color {
        colorScheme == .dark ? .orange : .orange
    }
    
    private var glowIntensity: Double {
        colorScheme == .dark ? 0.8 : 0.4
    }
    
    var body: some View {
        ZStack {
            StarShape(points: 5, innerRatio: 0.4)
                .fill(starColor)
                .frame(width: size, height: size)
                .overlay(
                    StarShape(points: 5, innerRatio: 0.4)
                        .stroke(outlineColor, lineWidth: max(1, size * 0.1))
                )
                .shadow(color: .yellow.opacity(glow ? glowIntensity : glowIntensity * 0.5),
                       radius: glow ? size * 0.3 : size * 0.1)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
            
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            .yellow.opacity(0.8),
                            .yellow.opacity(0.4),
                            .yellow.opacity(0.1),
                            .clear
                        ]),
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size * 1.2, height: size * 1.2)
                .opacity(glow ? 0.6 : 0.2)
        }
        .position(x: x, y: y)
        .onAppear {
            withAnimation(Animation.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glow.toggle()
                scale = glow ? 1.1 : 0.95
            }
        }
    }
}

// Forme d'étoile réutilisable
struct StarShape: Shape {
    let points: Int
    let innerRatio: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRatio
        
        for i in 0..<points * 2 {
            let angle = .pi * Double(i) / Double(points)
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
