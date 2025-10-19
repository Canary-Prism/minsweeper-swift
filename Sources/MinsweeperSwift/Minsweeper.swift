
public protocol Minsweeper {

    func start() -> GameState

    func getGameState() -> GameState 

    func reveal(x: Int, y: Int) -> GameState

    func clearAround(x: Int, y: Int) -> GameState

    func setFlagged(x: Int, y: Int, _ flagged: Bool) -> GameState

    func toggleFlag(x: Int, y: Int) -> GameState

    func leftClick(x: Int, y: Int) -> GameState 

    func rightClick(x: Int, y: Int) -> GameState
}

public extension Minsweeper {

    func toggleFlag(x: Int, y: Int) -> GameState {
        return setFlagged(x: x, y: y, getGameState().board[x, y].state != .flagged)
    }

    func leftClick(x: Int, y: Int) -> GameState {
        guard (getGameState().status == .playing) else { return getGameState() }
        guard (0..<getGameState().board.size.width ~= x && 0..<getGameState().board.size.height ~= y) else { return getGameState() }
        
        let cell = getGameState().board[x, y];

        func isSafe(cell: Cell) -> Bool {
            if case .safe = cell.type { true } else { false }
        }
        
        if (isSafe(cell: cell) && cell.state == .revealed) {
            return clearAround(x: x, y: y)
        } 
        if (cell.state == .unknown) {
            return reveal(x: x, y: y)
        }
        return getGameState();
    }

    func rightClick(x: Int, y: Int) -> GameState {
        return toggleFlag(x: x, y: y)
    }
}

public struct GameState {
    public var status: GameStatus
    public var board: Board
    public var remainingMines: Int

    func hideMines() -> GameState {
        var copy = self
        copy.board = copy.board.hideMines()
        return copy
    }
}

public enum GameStatus {
    case playing, won, lost, never
}