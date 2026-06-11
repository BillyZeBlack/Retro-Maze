//
//  MazeSpriteBoard.swift
//  Snail Maze like2
//
//  Created by Codex on 11/06/2026.
//

import SpriteKit
import SwiftUI
import UIKit

struct MazeSpriteBoard: UIViewRepresentable {
    let maze: Maze
    let playerX: Int
    let playerY: Int
    let showPath: Bool
    let itemPosition: (x: Int, y: Int)?
    let itemCollected: Bool
    let stepDuration: Double
    let isDarkMode: Bool
    let onSwipe: (Direction) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSwipe: onSwipe)
    }

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.backgroundColor = .clear
        view.allowsTransparency = true
        view.ignoresSiblingOrder = true

        context.coordinator.scene.scaleMode = .resizeFill
        view.presentScene(context.coordinator.scene)

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)

        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        context.coordinator.onSwipe = onSwipe

        let applyUpdate = {
            context.coordinator.scene.size = view.bounds.size
            context.coordinator.scene.configure(
                maze: maze,
                playerX: playerX,
                playerY: playerY,
                showPath: showPath,
                itemPosition: itemPosition,
                itemCollected: itemCollected,
                stepDuration: stepDuration,
                isDarkMode: isDarkMode
            )
        }

        if view.bounds.size == .zero {
            DispatchQueue.main.async(execute: applyUpdate)
        } else {
            applyUpdate()
        }
    }

    final class Coordinator: NSObject {
        let scene = MazeGameScene()
        var onSwipe: (Direction) -> Void

        init(onSwipe: @escaping (Direction) -> Void) {
            self.onSwipe = onSwipe
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard recognizer.state == .ended else { return }

            let translation = recognizer.translation(in: recognizer.view)
            guard max(abs(translation.x), abs(translation.y)) >= 24 else { return }

            let direction: Direction = abs(translation.x) > abs(translation.y)
                ? (translation.x > 0 ? .right : .left)
                : (translation.y > 0 ? .down : .up)

            onSwipe(direction)
        }
    }
}

final class MazeGameScene: SKScene {
    private let boardNode = SKNode()
    private let contentNode = SKNode()
    private let dynamicNode = SKNode()
    private let playerNode = SKShapeNode(circleOfRadius: 10)

    private var boardRect: CGRect = .zero
    private var cellSize: CGFloat = 0
    private var lineWidth: CGFloat = 1

    private var previousLayoutKey = ""
    private var previousPlayerCell: (x: Int, y: Int)?

    override init(size: CGSize = .zero) {
        super.init(size: size)
        backgroundColor = .clear
        anchorPoint = .zero

        addChild(boardNode)
        boardNode.addChild(contentNode)
        boardNode.addChild(dynamicNode)
        dynamicNode.addChild(playerNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        maze: Maze,
        playerX: Int,
        playerY: Int,
        showPath: Bool,
        itemPosition: (x: Int, y: Int)?,
        itemCollected: Bool,
        stepDuration: Double,
        isDarkMode: Bool
    ) {
        guard size.width > 0, size.height > 0 else { return }

        let itemKey = itemPosition.map { "\($0.x),\($0.y)" } ?? "nil"
        let layoutKey = [
            "\(Int(size.width))x\(Int(size.height))",
            "\(maze.cols)x\(maze.rows)",
            mazeSignature(maze),
            "\(showPath)",
            itemKey,
            "\(itemCollected)",
            "\(isDarkMode)"
        ].joined(separator: "|")

        let shouldRebuild = layoutKey != previousLayoutKey

        if shouldRebuild {
            previousLayoutKey = layoutKey
            rebuildStaticContent(
                maze: maze,
                showPath: showPath,
                itemPosition: itemPosition,
                itemCollected: itemCollected,
                isDarkMode: isDarkMode
            )
        }

        updatePlayer(
            x: playerX,
            y: playerY,
            duration: shouldRebuild ? 0 : stepDuration,
            isDarkMode: isDarkMode
        )
    }

    private func rebuildStaticContent(
        maze: Maze,
        showPath: Bool,
        itemPosition: (x: Int, y: Int)?,
        itemCollected: Bool,
        isDarkMode: Bool
    ) {
        contentNode.removeAllChildren()
        dynamicNode.removeAllChildren()
        dynamicNode.addChild(playerNode)

        let side = min(size.width, size.height)
        let padding: CGFloat = 12
        let available = side - padding * 2
        cellSize = min(available / CGFloat(maze.cols), available / CGFloat(maze.rows))
        lineWidth = max(1, cellSize * (maze.cols <= 7 ? 0.25 : 0.15))

        let totalWidth = CGFloat(maze.cols) * cellSize
        let totalHeight = CGFloat(maze.rows) * cellSize
        let originX = (size.width - totalWidth) / 2
        let originY = (size.height - totalHeight) / 2
        boardRect = CGRect(x: originX, y: originY, width: totalWidth, height: totalHeight)

        drawBackground(isDarkMode: isDarkMode)
        drawWalls(maze: maze, isDarkMode: isDarkMode)

        if showPath {
            drawSolutionPath(maze: maze, isDarkMode: isDarkMode)
        }

        if let itemPosition, !itemCollected {
            drawItem(at: itemPosition)
            drawLockedExit(maze: maze)
        }
    }

    private func updatePlayer(x: Int, y: Int, duration: Double, isDarkMode: Bool) {
        let radius = max(3, (cellSize - lineWidth * 1.8) / 2)
        let target = centerOfCell(x: x, y: y)

        playerNode.path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        playerNode.fillColor = .systemYellow
        playerNode.strokeColor = .clear
        playerNode.glowWidth = isDarkMode ? radius * 0.35 : radius * 0.18

        let oldCell = previousPlayerCell
        previousPlayerCell = (x, y)

        guard duration > 0, oldCell != nil else {
            playerNode.removeAllActions()
            playerNode.position = target
            return
        }

        playerNode.removeAllActions()
        playerNode.run(.move(to: target, duration: duration))
    }

    private func drawBackground(isDarkMode: Bool) {
        let side = min(size.width, size.height)
        let frame = CGRect(x: (size.width - side) / 2, y: (size.height - side) / 2, width: side, height: side)
        let background = SKShapeNode(rect: frame, cornerRadius: 12)
        background.fillColor = isDarkMode ? UIColor(white: 0.15, alpha: 1) : UIColor(white: 0.96, alpha: 1)
        background.strokeColor = .clear
        background.zPosition = -10
        contentNode.addChild(background)
    }

    private func drawWalls(maze: Maze, isDarkMode: Bool) {
        let wallColor = isDarkMode ? UIColor.white.withAlphaComponent(0.9) : .label

        for cell in maze.grid {
            let x = boardRect.minX + CGFloat(cell.x) * cellSize
            let y = boardRect.minY + CGFloat(cell.y) * cellSize

            if cell.walls[0] {
                addWall(from: CGPoint(x: x, y: y), to: CGPoint(x: x + cellSize, y: y), color: wallColor)
            }
            if cell.walls[1] {
                addWall(from: CGPoint(x: x + cellSize, y: y), to: CGPoint(x: x + cellSize, y: y + cellSize), color: wallColor)
            }
            if cell.walls[2] {
                addWall(from: CGPoint(x: x, y: y + cellSize), to: CGPoint(x: x + cellSize, y: y + cellSize), color: wallColor)
            }
            if cell.walls[3] {
                addWall(from: CGPoint(x: x, y: y), to: CGPoint(x: x, y: y + cellSize), color: wallColor)
            }
        }

        for y in 0...maze.rows {
            for x in 0...maze.cols {
                let point = CGPoint(
                    x: boardRect.minX + CGFloat(x) * cellSize,
                    y: boardRect.minY + CGFloat(y) * cellSize
                )
                let dot = SKShapeNode(circleOfRadius: lineWidth / 2)
                dot.position = spritePoint(point)
                dot.fillColor = wallColor
                dot.strokeColor = .clear
                dot.zPosition = 2
                contentNode.addChild(dot)
            }
        }
    }

    private func drawSolutionPath(maze: Maze, isDarkMode: Bool) {
        let solution = maze.solve()
        guard solution.count > 1 else { return }

        let path = CGMutablePath()
        for (index, cell) in solution.enumerated() {
            let point = centerOfCell(x: cell.x, y: cell.y)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        let line = SKShapeNode(path: path)
        line.strokeColor = isDarkMode ? .systemOrange : .systemRed
        line.lineWidth = lineWidth * 0.8
        line.lineCap = .round
        line.lineJoin = .round
        line.alpha = 0.8
        line.zPosition = 1
        contentNode.addChild(line)

        for cell in solution {
            let dot = SKShapeNode(circleOfRadius: lineWidth * 0.4)
            dot.position = centerOfCell(x: cell.x, y: cell.y)
            dot.fillColor = line.strokeColor
            dot.strokeColor = .clear
            dot.alpha = 0.9
            dot.zPosition = 2
            contentNode.addChild(dot)
        }
    }

    private func drawItem(at itemPosition: (x: Int, y: Int)) {
        let size = cellSize * 0.6
        let star = SKShapeNode(path: starPath(size: size))
        star.position = centerOfCell(x: itemPosition.x, y: itemPosition.y)
        star.fillColor = .systemYellow
        star.strokeColor = .systemOrange
        star.lineWidth = max(1, size * 0.08)
        star.glowWidth = size * 0.12
        star.zPosition = 5
        star.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 4)))

        let pulseUp = SKAction.scale(to: 1.1, duration: 0.75)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.scale(to: 0.95, duration: 0.75)
        pulseDown.timingMode = .easeInEaseOut
        star.run(.repeatForever(.sequence([pulseUp, pulseDown])))

        dynamicNode.addChild(star)
    }

    private func drawLockedExit(maze: Maze) {
        let center = centerOfCell(x: maze.cols - 1, y: 0)
        let lockSize = cellSize * 0.4

        let body = SKShapeNode(rectOf: CGSize(width: lockSize, height: lockSize * 0.7), cornerRadius: 2)
        body.position = CGPoint(x: center.x, y: center.y - lockSize * 0.05)
        body.fillColor = .systemRed
        body.strokeColor = .clear
        body.zPosition = 4
        dynamicNode.addChild(body)

        let arc = CGMutablePath()
        arc.addArc(
            center: CGPoint(x: 0, y: lockSize * 0.2),
            radius: lockSize * 0.3,
            startAngle: 0,
            endAngle: .pi,
            clockwise: false
        )

        let shackle = SKShapeNode(path: arc)
        shackle.position = center
        shackle.strokeColor = .white
        shackle.lineWidth = max(1, lockSize * 0.1)
        shackle.lineCap = .round
        shackle.zPosition = 5
        dynamicNode.addChild(shackle)
    }

    private func addWall(from start: CGPoint, to end: CGPoint, color: UIColor) {
        let shadowPath = CGMutablePath()
        shadowPath.move(to: spritePoint(CGPoint(x: start.x + 1, y: start.y + 1)))
        shadowPath.addLine(to: spritePoint(CGPoint(x: end.x + 1, y: end.y + 1)))

        let shadow = SKShapeNode(path: shadowPath)
        shadow.strokeColor = UIColor.black.withAlphaComponent(0.18)
        shadow.lineWidth = lineWidth * 0.35
        shadow.lineCap = .round
        shadow.zPosition = 1
        contentNode.addChild(shadow)

        let path = CGMutablePath()
        path.move(to: spritePoint(start))
        path.addLine(to: spritePoint(end))

        let wall = SKShapeNode(path: path)
        wall.strokeColor = color
        wall.lineWidth = lineWidth
        wall.lineCap = .round
        wall.lineJoin = .round
        wall.zPosition = 2
        contentNode.addChild(wall)
    }

    private func centerOfCell(x: Int, y: Int) -> CGPoint {
        spritePoint(CGPoint(
            x: boardRect.minX + CGFloat(x) * cellSize + cellSize / 2,
            y: boardRect.minY + CGFloat(y) * cellSize + cellSize / 2
        ))
    }

    private func spritePoint(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x, y: size.height - point.y)
    }

    private func starPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let points = 5
        let outerRadius = size / 2
        let innerRadius = outerRadius * 0.4

        for index in 0..<(points * 2) {
            let angle = CGFloat.pi * CGFloat(index) / CGFloat(points) - CGFloat.pi / 2
            let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }

    private func mazeSignature(_ maze: Maze) -> String {
        maze.grid.map { cell in
            cell.walls.map { $0 ? "1" : "0" }.joined()
        }.joined(separator: ",")
    }
}
