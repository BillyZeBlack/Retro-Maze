//
//  Maze.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 22/09/2025.
//

import Foundation

public struct Maze {
    public let cols: Int
    public let rows: Int
    public private(set) var grid: [MazeCell]
    public var itemPosition: (x: Int, y: Int)? = nil

    public init(cols: Int, rows: Int, seed: UInt64? = nil) {
        self.cols = cols
        self.rows = rows
        self.grid = (0..<(cols * rows)).map { i in
            MazeCell(x: i % cols, y: i / cols)
        }
        self.generate(seed: seed)
    }

    // MARK: - Indexing helpers
    @inline(__always) private func idx(_ x: Int, _ y: Int) -> Int { y * cols + x }
    @inline(__always) private func inBounds(_ x: Int, _ y: Int) -> Bool {
        x >= 0 && y >= 0 && x < cols && y < rows
    }

    private func neighborsCoords(of cell: MazeCell) -> [(dir: Int, nx: Int, ny: Int)] {
        var n: [(Int, Int, Int)] = []
        if cell.y > 0            { n.append((0, cell.x, cell.y - 1)) }
        if cell.x < cols - 1     { n.append((1, cell.x + 1, cell.y)) }
        if cell.y < rows - 1     { n.append((2, cell.x, cell.y + 1)) }
        if cell.x > 0            { n.append((3, cell.x - 1, cell.y)) }
        return n
    }

    // MARK: - Generation (code existant inchangé)
    public mutating func generate(seed: UInt64?) {
        // ... (le code de génération existant reste inchangé)
        // Paramètres de comportement
        let pRecentBranches: Double = 0.88
        let straightnessBranches: Double = 0.80
        let spineRunMax: Int = 3
        let spineStraightProb: Double = 0.40
        let minDeadEndDepth: Int = 4
        let extendShortDeadEndsFrac: Double = 0.45

        var rng = RandomNumberGeneratorWithSeed(seed: seed)
        var g = grid

        // Frontier: cellules actives
        var frontier: [Int] = []
        var isSpine: Set<Int> = []
        var lastDirFrom: [Int: Int] = [:]
        var runLenFrom: [Int: Int] = [:]

        let start = idx(0, rows - 1)
        g[start].visited = true
        frontier.append(start)
        isSpine.insert(start)
        lastDirFrom[start] = -1
        runLenFrom[start] = 0

        func unvisitedNeighbors(_ i: Int) -> [(dir: Int, j: Int)] {
            let c = g[i]
            var res: [(Int, Int)] = []
            if c.y > 0 {
                let j = idx(c.x, c.y - 1); if !g[j].visited { res.append((0, j)) }
            }
            if c.x < cols - 1 {
                let j = idx(c.x + 1, c.y); if !g[j].visited { res.append((1, j)) }
            }
            if c.y < rows - 1 {
                let j = idx(c.x, c.y + 1); if !g[j].visited { res.append((2, j)) }
            }
            if c.x > 0 {
                let j = idx(c.x - 1, c.y); if !g[j].visited { res.append((3, j)) }
            }
            return res
        }

        func pickActiveIndex() -> Int {
            let useRecent = Double.random(in: 0...1, using: &rng) < pRecentBranches
            return useRecent ? frontier.last! : frontier[Int.random(in: 0..<frontier.count, using: &rng)]
        }

        func chooseNeighbor(from i: Int, options: [(dir: Int, j: Int)]) -> (dir: Int, j: Int) {
            let onSpine = isSpine.contains(i)
            let prevDir = lastDirFrom[i] ?? -1
            let run = runLenFrom[i] ?? 0

            if onSpine {
                if run >= spineRunMax {
                    if let turnOpt = options.first(where: { $0.dir != prevDir && prevDir != -1 }) {
                        return turnOpt
                    }
                }
                if prevDir != -1,
                   let straightOpt = options.first(where: { $0.dir == prevDir }),
                   Double.random(in: 0...1, using: &rng) < spineStraightProb {
                    return straightOpt
                } else {
                    let turnOptions = options.filter { $0.dir != prevDir && prevDir != -1 }
                    if !turnOptions.isEmpty {
                        return turnOptions[Int.random(in: 0..<turnOptions.count, using: &rng)]
                    }
                }
            } else {
                if prevDir != -1,
                   let straightOpt = options.first(where: { $0.dir == prevDir }),
                   Double.random(in: 0...1, using: &rng) < straightnessBranches {
                    return straightOpt
                }
            }
            return options[Int.random(in: 0..<options.count, using: &rng)]
        }

        while !frontier.isEmpty {
            let i = pickActiveIndex()
            var opts = unvisitedNeighbors(i)

            if opts.isEmpty {
                if let pos = frontier.firstIndex(of: i) { frontier.remove(at: pos) }
                continue
            }

            let chosen = chooseNeighbor(from: i, options: opts)

            g[i].walls[chosen.dir] = false
            let opp = (chosen.dir + 2) % 4
            g[chosen.j].walls[opp] = false

            g[chosen.j].visited = true
            frontier.append(chosen.j)

            if isSpine.contains(i) {
                isSpine.insert(chosen.j)
            }
            let prev = lastDirFrom[i] ?? -1
            lastDirFrom[i] = chosen.dir
            lastDirFrom[chosen.j] = chosen.dir
            let newRun = (prev == chosen.dir && prev != -1) ? ((runLenFrom[i] ?? 0) + 1) : 1
            runLenFrom[i] = newRun
            runLenFrom[chosen.j] = newRun
        }

        g[idx(0, rows - 1)].walls[3] = false
        g[idx(cols - 1, 0)].walls[1] = false

        for i in g.indices { g[i].visited = false }

        func degree(of i: Int) -> Int {
            var d = 0
            if g[i].walls[0] == false { d += 1 }
            if g[i].walls[1] == false { d += 1 }
            if g[i].walls[2] == false { d += 1 }
            if g[i].walls[3] == false { d += 1 }
            return d
        }

        func deadEndDepth(from i: Int) -> (depth: Int, path: [Int]) {
            var path: [Int] = [i]
            var cur = i
            var prev = -1
            var depth = 0
            while true {
                if degree(of: cur) != 1 || cur == idx(cols - 1, 0) || cur == idx(0, rows - 1) { break }
                var next = -1
                for dir in 0..<4 where g[cur].walls[dir] == false {
                    let nx = (g[cur].x + [0,1,0,-1][dir])
                    let ny = (g[cur].y + [-1,0,1,0][dir])
                    let j = idx(nx, ny)
                    if j != prev { next = j; break }
                }
                if next == -1 { break }
                prev = cur; cur = next; depth += 1; path.append(cur)
            }
            return (depth, path)
        }

        var deadEnds: [Int] = []
        for i in 0..<(cols * rows) {
            if degree(of: i) == 1 { deadEnds.append(i) }
        }

        var shortDeadEnds: [(i: Int, depth: Int, path: [Int])] = []
        for i in deadEnds {
            let (dep, path) = deadEndDepth(from: i)
            if dep < minDeadEndDepth { shortDeadEnds.append((i, dep, path)) }
        }

        if !shortDeadEnds.isEmpty {
            let k = Int(Double(shortDeadEnds.count) * extendShortDeadEndsFrac)
            let toExtend = shortDeadEnds.shuffled(using: &rng).prefix(k)

            for item in toExtend {
                guard let tip = item.path.first else { continue }
                let base = item.path.count >= 2 ? item.path[min(1, item.path.count-1)] : tip
                let prev = item.path.count >= 2 ? item.path[1] : tip
                let bx = g[base].x, by = g[base].y
                let px = g[prev].x, py = g[prev].y
                let dirGuess: Int = {
                    if bx == px && by == py { return -1 }
                    if bx == px && by < py { return 0 }
                    if bx < px && by == py { return 1 }
                    if bx == px && by > py { return 2 }
                    if bx > px && by == py { return 3 }
                    return -1
                }()

                let candidates: [Int] = {
                    if dirGuess == -1 { return [0,1,2,3] }
                    switch dirGuess {
                    case 0: return [0,1,3,2]
                    case 1: return [1,0,2,3]
                    case 2: return [2,1,3,0]
                    default: return [3,0,2,1]
                    }
                }()

                var current = tip
                var extended = 0
                for _ in 0..<2 {
                    var opened = false
                    for d in candidates {
                        let nx = g[current].x + [0,1,0,-1][d]
                        let ny = g[current].y + [-1,0,1,0][d]
                        if !inBounds(nx, ny) { continue }
                        let j = idx(nx, ny)
                        if degree(of: j) > 0 { continue }
                        g[current].walls[d] = false
                        let opp = (d + 2) % 4
                        g[j].walls[opp] = false
                        current = j
                        extended += 1
                        opened = true
                        break
                    }
                    if !opened { break }
                }
            }
        }

        grid = g
    }

    // MARK: - Solve (BFS pour la solution minimale)
    public func solve() -> [MazeCell] {
        let start = idx(0, rows - 1)
        let goal = idx(cols - 1, 0)
        var prev: [Int: Int] = [:]
        var q = [start]
        var seen = Set([start])

        while let cur = q.first {
            q.removeFirst()
            if cur == goal { break }
            let c = grid[cur]
            for (dir, nx, ny) in neighborsCoords(of: c) {
                if grid[cur].walls[dir] { continue }
                let j = idx(nx, ny)
                let opp = (dir + 2) % 4
                if grid[j].walls[opp] { continue }
                if !seen.contains(j) {
                    seen.insert(j); prev[j] = cur; q.append(j)
                }
            }
        }

        var path: [Int] = []
        var cur = goal
        while cur != start, let p = prev[cur] {
            path.append(cur); cur = p
        }
        path.append(start)
        path.reverse()
        return path.map { grid[$0] }
    }

    // MARK: - Movement feasibility
    public func canMove(fromX x: Int, y: Int, dir: Direction) -> Bool {
        guard x >= 0, y >= 0, x < cols, y < rows else { return false }
        let i = y * cols + x
        let c = grid[i]
        if c.walls[dir.wallIndex] { return false }
        let nx = x + dir.dx
        let ny = y + dir.dy
        guard nx >= 0, ny >= 0, nx < cols, ny < rows else { return false }
        let j = ny * cols + nx
        let opp = (dir.wallIndex + 2) % 4
        return grid[j].walls[opp] == false
    }

    // MARK: - Item Placement

    /// Trouve une cellule accessible hors du chemin optimal
    public mutating func placeItem() -> Bool {
        guard let position = findAccessibleCellOffPath() else { return false }
        itemPosition = position
        return true
    }

    private func findAccessibleCellOffPath() -> (x: Int, y: Int)? {
        let solution = solve()
        
        // Solution 1: Utiliser une structure hashable
        struct CellCoord: Hashable {
            let x: Int
            let y: Int
        }
        
        let solutionCells = Set(solution.map { CellCoord(x: $0.x, y: $0.y) })
        
        // Trouver toutes les cellules accessibles hors du chemin
        var accessibleOffPath: [(Int, Int)] = []
        
        for cell in grid {
            let coords = CellCoord(x: cell.x, y: cell.y)
            
            // Exclure les cellules du chemin optimal, le départ et l'arrivée
            if !solutionCells.contains(coords) &&
               coords.x != 0 && coords.y != rows-1 &&  // départ (bas-gauche)
               coords.x != cols-1 && coords.y != 0 {   // arrivée (haut-droite)
                
                // Vérifier l'accessibilité depuis le départ
                if isCellAccessibleFromStart(x: cell.x, y: cell.y) {
                    accessibleOffPath.append((cell.x, cell.y))
                }
            }
        }
        
        // Si aucune cellule accessible n'est trouvée, chercher des alternatives
        if accessibleOffPath.isEmpty {
            // Fallback: prendre une cellule aléatoire hors du chemin (même si moins accessible)
            for cell in grid {
                let coords = CellCoord(x: cell.x, y: cell.y)
                if !solutionCells.contains(coords) &&
                   coords.x != 0 && coords.y != rows-1 &&
                   coords.x != cols-1 && coords.y != 0 {
                    accessibleOffPath.append((cell.x, cell.y))
                }
            }
        }
        
        return accessibleOffPath.randomElement()
    }


    private func isCellAccessibleFromStart(x: Int, y: Int) -> Bool {
        let start = idx(0, rows - 1)
        let target = idx(x, y)
        
        var visited = Set<Int>()
        var queue = [start]
        visited.insert(start)
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if current == target { return true }
            
            let cell = grid[current]
            for (dir, nx, ny) in neighborsCoords(of: cell) {
                if grid[current].walls[dir] { continue }
                let neighborIdx = idx(nx, ny)
                let opp = (dir + 2) % 4
                if grid[neighborIdx].walls[opp] { continue }
                
                if !visited.contains(neighborIdx) {
                    visited.insert(neighborIdx)
                    queue.append(neighborIdx)
                }
            }
        }
        
        return false
    }

    /// Vérifie si le joueur a atteint l'objet
    public func hasReachedItem(playerX: Int, playerY: Int) -> Bool {
        guard let itemPos = itemPosition else { return false }
        return playerX == itemPos.x && playerY == itemPos.y
    }
}
