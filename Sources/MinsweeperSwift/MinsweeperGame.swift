
public class AbstractMinsweeper: Minsweeper {

    let sizes: BoardSize

    let on_win: () -> ()
    let on_lose: () -> ()

    var gamestate: GameState

    init(sizes: BoardSize, on_win: @escaping () -> (), on_lose: @escaping () -> ()) {
        self.sizes = sizes

        self.gamestate = .init(status: .never, board: .init(size: sizes), remainingMines: 0)

        self.on_win = on_win
        self.on_lose = on_lose
    }

    public func start() -> GameState {
        fatalError()
    }

    public func getGameState() -> GameState {
        gamestate
    }


    private func revealEmpty(x: Int, y: Int, board: inout Board) {
        guard case .safe(number: let n) = board[x, y].type, n == 0, board[x, y].state == .unknown else { return }
        
        board[x, y] = Cell(type: .empty, state: .revealed)
        for y2 in max(0, y - 1)...min(sizes.height - 1, y + 1) {
            for x2 in max(0, x - 1)...min(sizes.width - 1, x + 1) {
                let cell = board[x2, y2]
                if case .safe(let number) = cell.type, cell.state == .unknown {
                    if (number == 0) {
                        revealEmpty(x: x2, y: y2, board: &board)
                    } else {
                        board[x2, y2] = .init(type: .safe(number: number), state: .revealed)
                    }
                }
            }
        }
    }
    
    private func internalReveal(x: Int, y: Int, board: inout Board) -> Bool {
        guard board[x, y].state == .unknown else { return true }

        switch (board[x, y].type) {
            case .safe(number: let number):
            
            if (number == 0) {
                revealEmpty(x: x, y: y, board: &board);
            } else {
                board[x, y] = Cell(type: .safe(number: number), state: .revealed);
            }
            
            return true
            
            case .mine:

            board[x, y] = Cell(type: .mine, state: .revealed);
            return false;
            
            default: 
            
            return true;
        };
    }

    public func reveal(x: Int, y: Int) -> GameState {
        guard gamestate.status == .playing, 0..<sizes.width ~= x, 0..<sizes.height ~= y else { return getGameState() }
        
        var board = gamestate.board;
        
        let success = internalReveal(x: x, y: y, board: &board);

        self.gamestate.board = board
        
        if (!success) {
            self.gamestate.status = .lost
            
            self.on_lose()
            
            return getGameState()
        }
        
        if (gamestate.board.hasWon()) {
            self.gamestate.status = .won
            
            on_win();
            
            return getGameState();
        }
        
        
        return getGameState();
    }

    public func clearAround(x: Int, y: Int) -> GameState {
        guard gamestate.status == .playing, 0..<sizes.width ~= x, 0..<sizes.height ~= y else { return getGameState() }
        
        var board = gamestate.board;

        guard case .safe(number: let number) = board[x, y].type, board[x, y].state == .revealed else { return getGameState() }
        
        var marked_mines = 0;
        
        for y2 in max(0, y - 1)...min(sizes.height - 1, y + 1) {
            for x2 in max(0, x - 1)...min(sizes.width - 1, x + 1) {
                if board[x2, y2].state == .flagged {
                    marked_mines += 1
                }
            }
        }
        
        var success = true;
        
        if (marked_mines == number) {
            for y2 in max(0, y - 1)...min(sizes.height - 1, y + 1) {
                for x2 in max(0, x - 1)...min(sizes.width - 1, x + 1) {
                    success = internalReveal(x: x2, y: y2, board: &board) && success
                }
            }
        }


        self.gamestate.board = board
        
        if (!success) {
            self.gamestate.status = .lost
            
            self.on_lose()
            
            return getGameState()
        }
        
        if (gamestate.board.hasWon()) {
            self.gamestate.status = .won
            
            on_win();
            
            return getGameState();
        }
        
        
        return getGameState();
    }

    public func setFlagged(x: Int, y: Int, _ flagged: Bool) -> GameState {
        guard gamestate.status == .playing, 0..<sizes.width ~= x, 0..<sizes.height ~= y else { return getGameState() }

        let state = gamestate.board[x, y].state
        let type = gamestate.board[x, y].type
        guard state != .revealed else { return getGameState() }
        
        var board = gamestate.board;
        var remaining_mines = gamestate.remainingMines;
        
        remaining_mines += (flagged != (state == .flagged)) ?
                ((flagged) ? -1 : 1) : 0;
        
        board[x, y] = Cell(type: type, state: (flagged) ? .flagged : .unknown)
        
        self.gamestate.board = board
        self.gamestate.remainingMines = remaining_mines

        return getGameState();
    }

    
}

public class AbstractHidingMinsweeper: AbstractMinsweeper {
    public override func getGameState() -> GameState {
        let gamestate = super.getGameState()
        return (gamestate.status == .playing) ? gamestate.hideMines() : gamestate
    }
}

public class AbstractRandomMinsweeper: AbstractHidingMinsweeper {

    public override func start() -> GameState {

        self.gamestate = generateGame()

        return getGameState()
    }

    func generateGame() -> GameState {
        var temp_board = Board(size: sizes);
        var mines = 0;
        while (mines < sizes.mines) {
            
            let x = Int.random(in: 0..<sizes.width)
            let y = Int.random(in: 0..<sizes.height)
            
            if case .safe = temp_board[x, y].type {
                temp_board[x, y] = .init(type: .mine, state: .unknown)
                mines += 1
            }
        }
        
        generateNmbers(board: &temp_board);
        
        return .init(status: .playing, board: temp_board, remainingMines: sizes.mines)
    }
    
    private func generateNmbers(board: inout Board) {
        for y in 0..<sizes.height {
            for x in 0..<sizes.width {
                if case .safe = board[x, y].type {
                    board[x, y] = .init(type: .empty, state: .unknown)
                }
            }
        }

        for y in 0..<sizes.height {
            for x in 0..<sizes.width {
                if board[x, y].type == .mine {
                    for y2 in max(0, y - 1)...min(sizes.height - 1, y + 1) {
                        for x2 in max(0, x - 1)...min(sizes.width - 1, x + 1) {
                            if case .safe(number: let number) = board[x2, y2].type {
                                board[x2, y2] = .init(type: .safe(number: number + 1), state: .unknown)
                            }
                        }
                    }
                }
            }
        }
    }
}

public class SetMinsweeperGame: AbstractHidingMinsweeper {
    public init(state: GameState, on_win: @escaping () -> () = {}, on_lose: @escaping () -> () = {}) {
        super.init(sizes: state.board.size, on_win: on_win, on_lose: on_lose)
        self.gamestate = state
    }

    public override func start() -> GameState {
        fatalError()
    }
}

public final class MinsweeperGame: AbstractRandomMinsweeper {

    private var solver: Solver? = nil

    private var first = false

    public override init(sizes: BoardSize, on_win: @escaping () -> () = {}, on_lose: @escaping () -> () = {}) {
        super.init(sizes: sizes, on_win: on_win, on_lose: on_lose)
    }

    public convenience init(size: ConventionalSize, on_win: @escaping () -> () = {}, on_lose: @escaping () -> () = {}) {
        self.init(sizes: size.size, on_win: on_win, on_lose: on_lose)
    }

    public override func start() -> GameState {
        return start(solver: nil)
    }
    public func start(solver: Solver? = nil) -> GameState {

        self.solver = solver

        self.gamestate = .init(status: .playing, board: .init(size: sizes), remainingMines: sizes.mines)

        self.first = true

        return getGameState()
    }

    public override func reveal(x: Int, y: Int) -> GameState {
        guard gamestate.status == .playing else { return getGameState() }
        if (self.first) {
            self.first = false

            if let solver = self.solver {
                while (true) {
                    let original_state = generateGame()
                    let game = SetMinsweeperGame(state: original_state)
                    _ = game.reveal(x: x, y: y)

                    let result = solver.solve(minsweeper: game)

                    if (result == .won) {
                        self.gamestate = original_state
                        break
                    }
                }
            } else {
                while (true) {
                    let original_state = generateGame();
                    let game = SetMinsweeperGame(state: original_state);
                    let state = game.reveal(x: x, y: y);
                    
                    if (state.status == .playing) {
                        self.gamestate = original_state;
                        
                        break;
                    }
                }
            }
        }

        return super.reveal(x: x, y: y)
    }

    public override func setFlagged(x: Int, y: Int, _ flagged: Bool) -> GameState {
        return (first) ? getGameState() : super.setFlagged(x: x, y: y, flagged)
    }
}