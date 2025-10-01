//
//  MazeCanvas.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 22/09/2025.
//

import SwiftUI

struct MazeCanvas: View {
    let maze: Maze
    let drawSide: CGFloat
    let padding: CGFloat
    let showPath: Bool
    let itemPosition: (x: Int, y: Int)?
    let itemCollected: Bool
    @Environment(\.colorScheme) var colorScheme
    
    // Couleurs adaptatives
    private var wallColor: Color {
        colorScheme == .dark ? .white.opacity(0.9) : .primary
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.96)
    }
    
    private var pathColor: Color {
        colorScheme == .dark ? .orange : .red
    }
    
    var body: some View {
        let cols = CGFloat(maze.cols)
        let rows = CGFloat(maze.rows)
        
        let availableSpace = drawSide - 2 * padding
        let cellSize = min(availableSpace / cols, availableSpace / rows)
        
        let totalWidth = cols * cellSize
        let totalHeight = rows * cellSize
        let offX = (drawSide - totalWidth) / 2
        let offY = (drawSide - totalHeight) / 2
        
        let baseLineW = max(1, cellSize * (maze.cols <= 7 ? 0.25 : 0.15))
        let lineW = baseLineW
        
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .frame(width: drawSide, height: drawSide)
            
            Canvas { ctx, size in
                drawModernWalls(ctx: &ctx, offX: offX, offY: offY, cellSize: cellSize, lineW: lineW)
                
                if showPath {
                    drawSolutionPath(ctx: &ctx, offX: offX, offY: offY, cellSize: cellSize, lineW: lineW)
                }
                
                if let itemPos = itemPosition, !itemCollected {
                    drawItem(ctx: &ctx, itemPos: itemPos, offX: offX, offY: offY, cellSize: cellSize)
                }
                
                if itemPosition != nil && !itemCollected {
                    drawLockedExit(ctx: &ctx, offX: offX, offY: offY, cellSize: cellSize)
                }
            }
            .frame(width: drawSide, height: drawSide)
        }
        .compositingGroup()
        .shadow(color: colorScheme == .dark ? .black.opacity(0.5) : .black.opacity(0.1),
               radius: 4, x: 2, y: 2)
    }
    
    // MARK: - Dessin des murs modernes
    
    private func drawModernWalls(ctx: inout GraphicsContext, offX: CGFloat, offY: CGFloat, cellSize: CGFloat, lineW: CGFloat) {
        let wallGradient = LinearGradient(
            gradient: Gradient(colors: colorScheme == .dark ? [
                .white.opacity(0.8),
                .white.opacity(0.6),
                .white.opacity(0.8)
            ] : [
                .primary.opacity(0.9),
                .primary.opacity(0.7),
                .primary.opacity(0.9)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Murs horizontaux
        for y in 0...maze.rows {
            for x in 0..<maze.cols {
                let cellX = offX + CGFloat(x) * cellSize
                let cellY = offY + CGFloat(y) * cellSize
                
                if y > 0 {
                    let cellAbove = maze.grid.first { $0.x == x && $0.y == y-1 }
                    if cellAbove?.walls[2] == true {
                        drawWallSegment(ctx: &ctx,
                                      from: CGPoint(x: cellX, y: cellY),
                                      to: CGPoint(x: cellX + cellSize, y: cellY),
                                      width: lineW,
                                      gradient: wallGradient)
                    }
                } else if y == 0 {
                    drawWallSegment(ctx: &ctx,
                                  from: CGPoint(x: cellX, y: cellY),
                                  to: CGPoint(x: cellX + cellSize, y: cellY),
                                  width: lineW,
                                  gradient: wallGradient)
                }
                
                if y == maze.rows {
                    drawWallSegment(ctx: &ctx,
                                  from: CGPoint(x: cellX, y: cellY + cellSize),
                                  to: CGPoint(x: cellX + cellSize, y: cellY + cellSize),
                                  width: lineW,
                                  gradient: wallGradient)
                }
            }
        }
        
        // Murs verticaux
        for x in 0...maze.cols {
            for y in 0..<maze.rows {
                let cellX = offX + CGFloat(x) * cellSize
                let cellY = offY + CGFloat(y) * cellSize
                
                if x > 0 {
                    let cellLeft = maze.grid.first { $0.x == x-1 && $0.y == y }
                    if cellLeft?.walls[1] == true {
                        drawWallSegment(ctx: &ctx,
                                      from: CGPoint(x: cellX, y: cellY),
                                      to: CGPoint(x: cellX, y: cellY + cellSize),
                                      width: lineW,
                                      gradient: wallGradient)
                    }
                } else if x == 0 {
                    drawWallSegment(ctx: &ctx,
                                  from: CGPoint(x: cellX, y: cellY),
                                  to: CGPoint(x: cellX, y: cellY + cellSize),
                                  width: lineW,
                                  gradient: wallGradient)
                }
                
                if x == maze.cols {
                    drawWallSegment(ctx: &ctx,
                                  from: CGPoint(x: cellX + cellSize, y: cellY),
                                  to: CGPoint(x: cellX + cellSize, y: cellY + cellSize),
                                  width: lineW,
                                  gradient: wallGradient)
                }
            }
        }
        
        drawWallCorners(ctx: &ctx, offX: offX, offY: offY, cellSize: cellSize, lineW: lineW)
    }
    
    private func drawWallSegment(ctx: inout GraphicsContext, from: CGPoint, to: CGPoint, width: CGFloat, gradient: LinearGradient) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        
        let style = StrokeStyle(
            lineWidth: width,
            lineCap: .round,
            lineJoin: .round,
            miterLimit: 2
        )
        
        ctx.stroke(path, with: .color(wallColor), style: style)
        
        var shadowPath = Path()
        shadowPath.move(to: from)
        shadowPath.addLine(to: to)
        
        ctx.stroke(shadowPath, with: .color(.black.opacity(0.2)),
                  style: StrokeStyle(lineWidth: width * 0.3, lineCap: .round))
    }
    
    private func drawWallCorners(ctx: inout GraphicsContext, offX: CGFloat, offY: CGFloat, cellSize: CGFloat, lineW: CGFloat) {
        for y in 0...maze.rows {
            for x in 0...maze.cols {
                let cornerX = offX + CGFloat(x) * cellSize
                let cornerY = offY + CGFloat(y) * cellSize
                
                var cornerPath = Path()
                cornerPath.addEllipse(in: CGRect(
                    x: cornerX - lineW/2,
                    y: cornerY - lineW/2,
                    width: lineW,
                    height: lineW
                ))
                
                ctx.fill(cornerPath, with: .color(wallColor))
            }
        }
    }
    
    // MARK: - Dessin du chemin de solution
    
    private func drawSolutionPath(ctx: inout GraphicsContext, offX: CGFloat, offY: CGFloat, cellSize: CGFloat, lineW: CGFloat) {
        let solution = maze.solve()
        guard solution.count > 1 else { return }
        
        var path = Path()
        
        for (index, mazeCell) in solution.enumerated() {
            let x = offX + CGFloat(mazeCell.x) * cellSize + cellSize/2
            let y = offY + CGFloat(mazeCell.y) * cellSize + cellSize/2
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        let style = StrokeStyle(
            lineWidth: lineW * 0.8,
            lineCap: .round,
            lineJoin: .round
        )
        
        ctx.stroke(path, with: .color(pathColor), style: style)
        
        for mazeCell in solution {
            let x = offX + CGFloat(mazeCell.x) * cellSize + cellSize/2
            let y = offY + CGFloat(mazeCell.y) * cellSize + cellSize/2
            
            var dotPath = Path()
            dotPath.addEllipse(in: CGRect(
                x: x - lineW * 0.4,
                y: y - lineW * 0.4,
                width: lineW * 0.8,
                height: lineW * 0.8
            ))
            
            ctx.fill(dotPath, with: .color(pathColor))
        }
    }
    
    // MARK: - Dessin de l'objet
    
    private func drawItem(ctx: inout GraphicsContext, itemPos: (x: Int, y: Int), offX: CGFloat, offY: CGFloat, cellSize: CGFloat) {
        let x = offX + CGFloat(itemPos.x) * cellSize + cellSize/2
        let y = offY + CGFloat(itemPos.y) * cellSize + cellSize/2
        let size = cellSize * 0.6
        
        let star = StarShape(points: 5, innerRatio: 0.4).path(in: CGRect(
            x: x - size/2,
            y: y - size/2,
            width: size,
            height: size
        ))
        
        ctx.fill(star, with: .color(.yellow))
        
        let outlineStyle = StrokeStyle(
            lineWidth: max(1, size * 0.08),
            lineCap: .round,
            lineJoin: .round
        )
        
        ctx.stroke(star, with: .color(.orange), style: outlineStyle)
        
        var glowPath = Path()
        glowPath.addEllipse(in: CGRect(
            x: x - size * 0.15,
            y: y - size * 0.15,
            width: size * 0.3,
            height: size * 0.3
        ))
        
        ctx.fill(glowPath, with: .color(.white.opacity(0.3)))
    }
    
    // MARK: - Dessin de la sortie verrouillée
    
    private func drawLockedExit(ctx: inout GraphicsContext, offX: CGFloat, offY: CGFloat, cellSize: CGFloat) {
        let exitX = offX + CGFloat(maze.cols - 1) * cellSize + cellSize/2
        let exitY = offY + CGFloat(0) * cellSize + cellSize/2
        let lockSize = cellSize * 0.4
        
        // Corps du cadenas
        var lockBody = Path()
        lockBody.addRoundedRect(in: CGRect(
            x: exitX - lockSize/2,
            y: exitY - lockSize/2,
            width: lockSize,
            height: lockSize * 0.7
        ), cornerSize: CGSize(width: 2, height: 2))
        
        // Arc du cadenas
        var lockArc = Path()
        lockArc.addArc(center: CGPoint(x: exitX, y: exitY - lockSize/2),
                      radius: lockSize * 0.3,
                      startAngle: .degrees(0),
                      endAngle: .degrees(180),
                      clockwise: false)
        
        ctx.fill(lockBody, with: .color(.red))
        ctx.stroke(lockArc, with: .color(.white),
                  style: StrokeStyle(lineWidth: max(1, lockSize * 0.1)))
    }
}
