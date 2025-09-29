//
//  MazeViewModel.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 22/09/2025.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class MazeViewModel: ObservableObject {
    // MARK: - Model
    @Published private(set) var maze: Maze = .init(cols: 5, rows: 5, seed: nil)
    @Published var showPath: Bool = false

    // MARK: - Player
    @Published private(set) var playerX: Int = 0
    @Published private(set) var playerY: Int = 0

    // MARK: - Item System
    @Published private(set) var itemCollected: Bool = false
    @Published private(set) var requiresItem: Bool = false
    @Published private(set) var levelsCompleted: Int = 0

    // MARK: - Premium Features
    @Published var hasPremiumPack: Bool = false {
        didSet {
            if hasPremiumPack {
                UserDefaults.standard.set(true, forKey: "hasPremiumPack")
            }
        }
    }
    @Published private(set) var showSolutionAfterFailure: Bool = false
    @Published private(set) var solutionTimer: Double = 0.0
    private let solutionDuration: Double = 15.0

    // MARK: - Movement
    @Published var stepDuration: Double = 0.22
    private var isMoving: Bool = false
    private var currentDirection: Direction? = nil

    // Mémoire d'intentions
    private struct Intent {
        let dir: Direction
        let expiresAt: Date
    }
    private var intentQueue: [Intent] = []
    private let intentTTL: TimeInterval = 0.8
    private let maxIntentQueue: Int = 3

    // MARK: - Timer
    @Published private(set) var timeLeft: Double = 0.0
    @Published var timerRunning: Bool = true
    private let humanOverhead: Double = 0.04
    private let baseBuffer: Double = 5
    private let fixedBonusPerLevel: Double = 30

    // Services
    let tone = ModernToneEngine()
    private let storeManager = StoreManager()

    // Tick
    private var ticker: AnyCancellable?
    private let tickInterval: Double = 0.1

    init() {
        checkPremiumStatus()
        resetPlayer()
        recalcAndResetTimerForCurrentMaze(carry: 0)
        ticker = Timer.publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    // MARK: - Public API

    func handleSwipe(_ dir: Direction) {
        enqueueIntent(dir)
        if !isMoving { tryStartMovement() }
    }

    // MARK: - Premium Features Management

    func activatePremiumPack() {
        Task {
            let success = await storeManager.purchasePremiumPack()
            if success {
                hasPremiumPack = true
                print("✅ Pack premium activé avec succès")
            } else {
                print("❌ Échec de l'activation du pack premium")
            }
        }
    }

    func checkPremiumStatus() {
        if storeManager.hasPremiumPack || UserDefaults.standard.bool(forKey: "hasPremiumPack") {
            hasPremiumPack = true
        }
    }

    func showSolutionAfterTimeout() {
        guard hasPremiumPack && !showSolutionAfterFailure else { return }
        
        showSolutionAfterFailure = true
        solutionTimer = solutionDuration
        showPath = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + solutionDuration) {
            self.hideSolution()
        }
    }

    private func hideSolution() {
        showSolutionAfterFailure = false
        solutionTimer = 0.0
        showPath = false
    }

    // MARK: - Item System

    private func setupItemForCurrentLevel() {
        let currentPalier = (levelsCompleted / 10) + 1
        requiresItem = (currentPalier >= 2)
        
        if requiresItem {
            itemCollected = false
            _ = maze.placeItem()
        } else {
            itemCollected = true
            maze.itemPosition = nil
        }
    }

    private func checkItemCollection() {
        if requiresItem && !itemCollected && maze.hasReachedItem(playerX: playerX, playerY: playerY) {
            itemCollected = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.tone.successJingle()
            }
        }
    }

    // MARK: - Intents

    private func pruneExpiredIntents(_ now: Date = Date()) {
        intentQueue.removeAll { $0.expiresAt <= now }
    }

    private func enqueueIntent(_ dir: Direction) {
        let now = Date()
        pruneExpiredIntents(now)
        if intentQueue.count >= maxIntentQueue {
            intentQueue.removeFirst(intentQueue.count - maxIntentQueue + 1)
        }
        intentQueue.append(.init(dir: dir, expiresAt: now.addingTimeInterval(intentTTL)))
    }

    private func nextDesiredDirection() -> Direction? {
        pruneExpiredIntents()
        return intentQueue.first?.dir
    }

    private func consumeDesiredIfMatching(_ dir: Direction) {
        pruneExpiredIntents()
        if let first = intentQueue.first, first.dir == dir {
            intentQueue.removeFirst()
        }
    }

    // MARK: - Movement core

    private func tryStartMovement() {
        if currentDirection == nil {
            if let want = nextDesiredDirection(),
               maze.canMove(fromX: playerX, y: playerY, dir: want) {
                currentDirection = want
                consumeDesiredIfMatching(want)
            } else { return }
        }
        isMoving = true
        movementStepLoop()
    }

    private func movementStepLoop() {
        guard isMoving else { return }

        checkItemCollection()

        if let want = nextDesiredDirection(), canTurnNow(to: want) {
            currentDirection = want
            consumeDesiredIfMatching(want)
        }

        guard let dir = currentDirection else { isMoving = false; return }

        if maze.canMove(fromX: playerX, y: playerY, dir: dir) {
            withAnimation(.easeInOut(duration: stepDuration)) {
                playerX += dir.dx
                playerY += dir.dy
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration) {
                self.checkItemCollection()
                if self.reachedGoal() {
                    self.handleSuccess()
                } else {
                    self.movementStepLoop()
                }
            }
        } else {
            if let want = nextDesiredDirection(), canTurnNow(to: want) {
                currentDirection = want
                consumeDesiredIfMatching(want)
                movementStepLoop()
            } else {
                isMoving = false
                currentDirection = nil
            }
        }
    }

    private func canTurnNow(to d: Direction) -> Bool {
        maze.canMove(fromX: playerX, y: playerY, dir: d)
    }

    private func reachedGoal() -> Bool {
        let atGoal = playerX == maze.cols - 1 && playerY == 0
        return atGoal && (!requiresItem || itemCollected)
    }

    // MARK: - Timer sizing

    private func timeBudgetForCurrentMaze(carry: Double) -> Double {
        let steps = max(0, maze.solve().count - 1)
        let base = Double(steps) * (stepDuration + humanOverhead)
        return max(5, base + baseBuffer + fixedBonusPerLevel + carry)
    }

    private func recalcAndResetTimerForCurrentMaze(carry: Double) {
        timeLeft = timeBudgetForCurrentMaze(carry: carry)
        timerRunning = true
    }

    // MARK: - Tick

    private func tick() {
        guard timerRunning else { return }
        
        if timeLeft > 0 {
            timeLeft = max(0, timeLeft - tickInterval)
            tone.updateUrgency(timeLeft: timeLeft)
        }
        
        if showSolutionAfterFailure {
            solutionTimer = max(0, solutionTimer - tickInterval)
        }
        
        if timeLeft <= 0 {
            handleTimeout()
        }
    }

    // MARK: - Flow

    private func handleTimeout() {
        if reachedGoal() { handleSuccess(); return }
        
        timerRunning = false
        isMoving = false
        currentDirection = nil
        tone.timeoutBuzz()
        
        showSolutionAfterTimeout()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (hasPremiumPack ? solutionDuration : 2.0)) {
            self.resetPlayer()
            self.recalcAndResetTimerForCurrentMaze(carry: 0)
            self.tone.updateUrgency(timeLeft: self.timeLeft)
        }
    }

    private func handleSuccess() {
        timerRunning = false
        isMoving = false
        currentDirection = nil

        if requiresItem && !itemCollected {
            return
        }

        let carry = ceil(max(0, timeLeft) / 2.0)
        tone.successJingle()

        levelsCompleted += 1

        let maxSize = 27
        let newCols = min(maxSize, maze.cols + 2)
        let newRows = min(maxSize, maze.rows + 2)
        
        maze = Maze(cols: newCols, rows: newRows, seed: nil)
        setupItemForCurrentLevel()
        
        resetPlayer()
        timeLeft = timeBudgetForCurrentMaze(carry: carry)
        timerRunning = true
        tone.updateUrgency(timeLeft: timeLeft)
    }

    // MARK: - Utils

    func formattedTime(_ t: Double) -> String {
        let s = max(0, t)
        let secs = floor(s)
        let tenth = Int((s - secs) * 10)
        return String(format: "%.0f.%ds", secs, tenth)
    }

    func formattedSolutionTime(_ t: Double) -> String {
        return String(format: "%.0f", t)
    }

    func resetPlayer() {
        playerX = 0
        playerY = maze.rows - 1
        isMoving = false
        currentDirection = nil
        intentQueue.removeAll()
        
        if requiresItem {
            itemCollected = false
        }
        
        if showSolutionAfterFailure {
            hideSolution()
        }
    }

    // MARK: - Public getters pour la vue
    var itemPosition: (x: Int, y: Int)? {
        return maze.itemPosition
    }
    
    // MARK: remise à zero premium
    
    func resetPremiumStatus() {
        hasPremiumPack = false
        UserDefaults.standard.set(false, forKey: "hasPremiumPack")
        storeManager.resetPremiumForTesting()
        print("✅ État premium réinitialisé")
    }
}
