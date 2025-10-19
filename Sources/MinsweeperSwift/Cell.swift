public struct Cell {
    public let type: CellType
    public let state: CellState
}

public enum CellType: Sendable, Equatable {
    public static let empty = CellType.safe(number: 0)

    case safe(number: Int)
    case mine
    case unknown
}

public enum CellState {
    case revealed, flagged, unknown
}