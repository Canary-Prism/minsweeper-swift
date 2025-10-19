
public protocol Solver {
    func solve(state: GameState) -> Move?
}

public extension Solver {
    func solve(minsweeper: Minsweeper) -> Result {
        while (minsweeper.getGameState().status == .playing) {
            if let move = solve(state: minsweeper.getGameState()) {
                switch (move.action) {
                    case .left:
                    _ = minsweeper.leftClick(x: move.point.x, y: move.point.y)
                    case .right:
                    _ = minsweeper.rightClick(x: move.point.x, y: move.point.y)
                }
            }
        }

        return switch (minsweeper.getGameState().status) {
            case .won: .won
            case .lost: .lost
            case .playing: .resigned
            case .never: fatalError()
        }
    }
}
public enum Result {
    case won, lost, resigned
}

// typealias Point = (x: Int, y: Int)

struct Point: Hashable {
    let x: Int
    let y: Int
}


public struct Move {
    let point: Point
    let action: Click
    public enum Click {
        case left, right
    }
}

func +=<T>(lhs: inout Set<T>, rhs: [T]) {
    lhs = lhs.union(rhs)
}

public struct MiaSolver: Solver, Sendable {
    public static let BRUTE_FORCE_LIMIT = 20;

    public static let instance = MiaSolver()
    
    public func solve(state: GameState) -> Move? {
        let size = state.board.size;

        if (state.status == .playing) {
            for y2 in 0..<size.height {
                for x2 in 0..<size.width {

                    guard case .safe(let number) = state.board[x2, y2].type else { continue }
                    
                    var marked_mines = 0;
                    var empty_spaces = 0;
                    
                    for y3 in max(0, y2 - 1)...min(size.height - 1, y2 + 1) {
                        for x3 in max(0, x2 - 1)...min(size.width - 1, x2 + 1) {
                            if (state.board[x3, y3].state == .flagged) {
                                marked_mines += 1
                                empty_spaces += 1
                            } else if (state.board[x3, y3].state == .unknown) {
                                empty_spaces += 1
                            }
                        }
                    }
                    
                    
                    if (number == marked_mines && empty_spaces > marked_mines) {
//                            try? await Task.sleep(nanoseconds: 50_000_000)
                        return .init(point: .init(x: x2, y: y2), action: .left)
                    } else if (number == empty_spaces) {
                        for y3 in max(0, y2 - 1)...min(size.height - 1, y2 + 1) {
                            for x3 in max(0, x2 - 1)...min(size.width - 1, x2 + 1) {
                                if (state.board[x3, y3].state == .unknown) {
                                    return .init(point: .init(x: x3, y: y3), action: .right)
                                }
                            }
                        }
                    } else if (number < marked_mines) {
                        for y3 in max(0, y2 - 1)...min(size.height - 1, y2 + 1) {
                            for x3 in max(0, x2 - 1)...min(size.width - 1, x2 + 1) {
                                if (state.board[x3, y3].state == .flagged) {
                                    return .init(point: .init(x: x3, y: y3), action: .right)
                                }
                            }
                        }
                    }
                }
            }
            
            //logical deduction time :c
            

            func logic(_ x2: Int, _ y2: Int, _ de: Int, _ grid: [Point]) -> Move? {
                guard case .safe(number: let this_num) = state.board[x2, y2].type else { return nil }
                
                var index = 0;
                var claimed_surroundings = [Int]();

                for y3 in max(0, y2 - 1)...min(size.height - 1, y2 + 1) {
                    for x3 in max(0, x2 - 1)...min(size.width - 1, x2 + 1) {
                        if (x3 == x2 && y3 == y2) {
                            index += 1
                        }
                        for item in grid {
                            if (item.x == x3 && item.y == y3) {
                                claimed_surroundings += [index]
                            }
                        }
                        index += 1
                    }
                }

                let strong_match = claimed_surroundings.count == grid.count
                var flagged = 0;
                var empty = 0;
                index = 0;

                for y3 in max(0, y2 - 1)...min(size.height - 1, y2 + 1) {
                    for x3 in max(0, x2 - 1)...min(size.width - 1, x2 + 1) {
                        if (x3 == x2 && y3 == y2) {
                            index += 1
                            continue
                        }
                        if (claimed_surroundings.contains(index)) {
                            index += 1
                            continue
                        }
                        switch (state.board[x3, y3].state) {
                            case .flagged:
                            flagged += 1
                            case .unknown:
                            empty += 1
                            default: break
                        }
                        index += 1
                    }
                }

                
                if (strong_match && flagged + de == this_num && empty > 0) {
                    index = 0;
                    for y3 in max(0, y2 - 1)...min(size.height - 1, y2 + 1) {
                        for x3 in max(0, x2 - 1)...min(size.width - 1, x2 + 1) {
                            if (x3 == x2 && y3 == y2) {
                                index += 1;
                                continue;
                            }
                            if (claimed_surroundings.contains(index)) {
                                index += 1
                                continue;
                            }
                            if (state.board[x3, y3].state == .unknown) {
//                                        try? await Task.sleep(nanoseconds: 50_000_000)
                                
                                return .init(point: .init(x: x3, y: y3), action: .left)
                            }
                            index += 1;
                        }
                    }
                } else if (flagged + de + empty == this_num) {
                    index = 0;
                    for y3 in max(0, y2 - 1)...min(size.height - 1, y2 + 1) {
                        for x3 in max(0, x2 - 1)...min(size.width - 1, x2 + 1) {
                            if (x3 == x2 && y3 == y2) {
                                index += 1;
                                continue;
                            }
                            if (claimed_surroundings.contains(index)) {
                                index += 1;
                                continue;
                            }
                            if (state.board[x3, y3].state == .unknown) {
                                return .init(point: .init(x: x3, y: y3), action: .right)
                            }
                            index += 1;
                        }
                    }
                }
                
                return nil;
            }
            
            for y2 in 0..<size.height {
                for x2 in 0..<size.width {
                    guard case .safe(number: let this_num) = state.board[x2, y2].type, this_num > 0 else { continue }
                    
                    var flagged = 0;
                    var empty = 0;
                    var grid = [Point]()
                    
                    for y3 in max(0, y2 - 1)...min(size.height - 1, y2 + 1) {
                        for x3 in max(0, x2 - 1)...min(size.width - 1, x2 + 1) {
                            if (state.board[x3, y3].state == .flagged) {
                                flagged += 1
                            } else if (state.board[x3, y3].state == .unknown) {
                                grid += [.init(x: x3, y: y3)]
                                empty += 1
                            }
                        }
                    }

                    if (!(flagged < this_num && empty > 0)) {
                        continue;
                    }
                    
                    let de = this_num - flagged;
                    
                    for y3 in max(0, y2 - 1)...min(size.height - 1, y2 + 1) {
                        for x3 in max(0, x2 - 1)...min(size.width - 1, x2 + 1) {
                            if (state.board[x3, y3].state == .revealed) {
                                if let move = logic(x3, y3, de, grid) {
                                    return move
                                }
                            }
                        }
                    }
                }
            }
            
        }
        
        
        if (state.remainingMines == 0) {
            for y2 in 0..<size.height {
                for x2 in 0..<size.width {
                    if (state.board[x2, y2].state == .unknown) {
                        return .init(point: .init(x: x2, y: y2), action: .left)
                    }
                }
            }
        }
        
        var empties: Set<Point> = []
        var adjacents: Set<Point> = []
        for y in 0..<size.height {
            for x in 0..<size.width {
                if (state.board[x, y].state == .unknown) {
                    for y2 in max(0, y - 1)...min(size.height - 1, y + 1) {
                        for x2 in max(0, x - 1)...min(size.width - 1, x + 1) {
                            if (state.board[x2, y2].state == .revealed) {
                                if case .safe(_) = state.board[x2, y2].type {
                                    empties += [.init(x: x, y: y)]
                                    adjacents += [.init(x: x2, y: y2)]
                                }
                            }
                        }
                    }
                }
            }
        }

//        System.out.println();
//        System.out.println("empties: " + empties.size());
//        System.out.println("adjacents: " + adjacents.size());
        if (empties.count < MiaSolver.BRUTE_FORCE_LIMIT && !adjacents.isEmpty) {
//            System.out.println("brute forcing");
//            var start = System.nanoTime();
//            try {
                
                let states = bruteForce(points: .init(adjacents), index: 0, state: state);
//        System.out.println("possible states");
//        for (var e : states) {
//            e.board().forEach(System.out::println);
//            System.out.println();
//        }
                if (!states.isEmpty) {
                    for point in empties {
                        if (states.allSatisfy { $0.board[point.x, point.y].state == .unknown }) {
                            return .init(point: point, action: .left)
                        }
                        if (states.allSatisfy { $0.board[point.x, point.y].state == .flagged }) {
                            return .init(point: point, action: .right)
                        }
                    }
                }
//                System.out.println("brute force without solution");
//            } finally {
//                System.out.printf("spent %.6f secs\n", (System.nanoTime() - start) / 1_000_000_000.0);
//            }
        } else {
//            System.out.println("skipping brute force: too many combinations");
        }
        
        
        return nil;
    }
    
    private func simulateRightClick(state: GameState, point: Point) -> GameState {
        return simulateRightClick(state: state, x: point.x, y: point.y);
    }
    private func simulateRightClick(state: GameState, x: Int, y: Int) -> GameState {
        var board = state.board
        let cell = board[x, y]
        var remaining = state.remainingMines;
        if (cell.state == .unknown) {
            board[x, y] = .init(type: .unknown, state: .flagged)
            remaining -= 1;
        } else if (cell.state == .flagged) {
            board[x, y] = .init(type: .unknown, state: .unknown)
            remaining += 1;
        }
        return .init(status: state.status, board: board, remainingMines: remaining)
    }
    
    /// this might actually return partially filled satisfied states since tehy might fail early??
    /// probably not though
    private func bruteForce(points: [Point], index: Int, state: GameState) -> [GameState] {
        let size = state.board.size
        var empties = [Point]();
        let current = points[index];
        let x = current.x;
        let y = current.y;
        var flags = 0;
        guard case .safe(number: let number) = state.board[x, y].type else { fatalError() }
        
        for y3 in max(0, y - 1)...min(size.height - 1, y + 1) {
            for x3 in max(0, x - 1)...min(size.width - 1, x + 1) {
                if (state.board[x3, y3].state == .revealed) {
                    if (state.board[x3, y3].state == .unknown) {
                        empties += [.init(x: x3, y: y3)]
                    } else if (state.board[x3, y3].state == .flagged) {
                        flags += 1
                    }
                }
            }
        }
        
        let mines_to_flag = number - flags;
        if (mines_to_flag == 0 || empties.isEmpty) {
            if (index + 1 == points.count) {
                return [state]
            }
            return bruteForce(points: points, index: index + 1, state: state);
        }
        
        if (mines_to_flag > state.remainingMines) {
            return [] // invalid
        }
        
        var stream = [[GameState]]();
        for flag_combination in getFlagCombinations(empties: empties, mines_to_flag: mines_to_flag) {
            var state_copy = state;
            for point in flag_combination {
                state_copy = simulateRightClick(state: state_copy, point: point);
            }
            if (index + 1 == points.count) {
                stream += [[state_copy]]
            } else {
                stream += [bruteForce(points: points, index: index + 1, state: state_copy)]
            }
        }

        return stream.flatMap { $0 }
    }
    
    private func getFlagCombinations(empties: [Point], mines_to_flag: Int) -> Set<Set<Point>> {
        if (empties.count < mines_to_flag) {
            return []
        }

        return .init(getFlagCombinations(selected: [], empties: empties, start: 0, mines_to_flag: mines_to_flag))
    }

    private func getFlagCombinations(selected: Set<Point>, empties: [Point], start: Int, mines_to_flag: Int) -> [Set<Point>] {
        if (mines_to_flag < 1) {
            return []
        }
        var stream: [[Set<Point>]] = [] 

        for i in start..<empties.count {
            var clone = selected
            clone += [empties[i]]
            if (mines_to_flag == 1) {
                stream += [[clone]]
            } else {
                stream += [getFlagCombinations(selected: clone, empties: empties, start: i + 1, mines_to_flag: mines_to_flag - 1)]
            }
        }
        return stream.flatMap { $0 }
    }
}