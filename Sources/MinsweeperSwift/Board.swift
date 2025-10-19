
public struct Board {

    public let size: BoardSize

    private var board: [[Cell]]

    public init(size: BoardSize, fill: Cell) {
        self.size = size
        self.board = .init(repeating: .init(repeating: fill, count: size.width), count: size.height)
    }

    public init(size: BoardSize) {
        self.init(size: size, fill: Cell(type: .empty, state: .unknown))
    }


    public subscript(_ x: Int, _ y: Int) -> Cell {
        get {
            board[y][x]
        }
        set(cell) {
            board[y][x] = cell
        }
    }

    func hideMines() -> Board {
        var copy = self
        copy.board = board.map { $0.map { ($0.state != .revealed) ? Cell(type: .unknown, state: $0.state) : $0 } }
        return copy
    }

    func hasWon() -> Bool {
        func isSafe(cell: Cell) -> Bool {
            if case .safe = cell.type { true } else { false }
        }

        return board.allSatisfy { $0.allSatisfy { !(($0.type == .mine && $0.state == .revealed)
                        || (isSafe(cell: $0)  && $0.state != .revealed)) } }
    }
     
}

public enum ConventionalSize {
    case beginner, intermediate, expert

    public var size: BoardSize {
        switch (self) {
            case .beginner:
                try! BoardSize(width: 9, height: 9, mines: 10)
            case .intermediate:
                try! BoardSize(width: 16, height: 16, mines: 40)
            case .expert:
                try! BoardSize(width: 30, height: 16, mines: 99)
        }
    }
}

public struct BoardSize {
    let width: Int
    let height: Int
    let mines: Int

    public init(width: Int, height: Int, mines: Int) throws(BoardSizeError) {
        if (width <= 0 || height <= 0) {
            throw .invalidSize
        }
        if (mines >= width * height) {
            throw .tooManyMines
        }
        if (mines <= 0) {
            throw .tooFewMines
        }

        self.width = width
        self.height = height
        self.mines = mines
    }
}


public enum BoardSizeError: Error {
    case invalidSize, tooManyMines, tooFewMines
}

