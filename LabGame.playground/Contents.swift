import Foundation

enum Rotation : Int {
    case Right, Left
}

protocol Rotate {
    mutating func rotate(_ rotation: Rotation)
}

enum Orientation : Int, Rotate, Codable  {
    case Vertical, Horizontal  // 2
    
    mutating func rotate(_ rotation: Rotation) {
        self = Orientation(rawValue: (self.rawValue + 1) % 2)!
    }
}

enum Direction : Int, Rotate, Codable  {
    case North, East, South, West // 4

    mutating func rotate(_ rotation: Rotation) {
        switch rotation {
        case .Right:
            self = Direction(rawValue: (self.rawValue + 1) % 4)!
        case .Left:
            if self == .North {
                self = .West
            }
            else {
                self = Direction(rawValue: (self.rawValue - 1) % 4)!
            }
        }
    }
}

enum BoxType : String, Codable {
    case None                               // X
    case Cross                              // +
    case Linear                             // - |
    case Curved                             // L ∧>∨<
    case Intersection                       // ⊤⊣⊥⊢
}

enum Box : Rotate, CustomStringConvertible, Codable {
    case None                               // X
    case Cross                              // +
    case Linear(orientation: Orientation)   // - |
    case Curved(direction: Direction)       // L ∧>∨<
    case Intersection(direction: Direction) // ⊤⊣⊥⊢
    
    mutating func rotate(_ rotation: Rotation) {
        switch self {
        case .None:
            break
        case .Cross:
            break
        case var .Linear(orientation):
            orientation.rotate(rotation)
            self = .Linear(orientation: orientation)
        case var .Curved(direction):
            direction.rotate(rotation)
            self = .Curved(direction: direction)
        case var .Intersection(direction):
            direction.rotate(rotation)
            self = .Intersection(direction: direction)
        }
    }
    
    var directions: [Direction] {
        var directions = [Direction]()
        
        switch self {
        case .None:                                 // X
            break
        case .Cross:                                // +
            directions.append(contentsOf: [.North, .East, .South, .West])
        case let .Linear(orientation):
            switch orientation {
            case .Horizontal:                       // -
                directions.append(contentsOf: [.East, .West])
            case .Vertical:                         // |
                directions.append(contentsOf: [.North, .South])
            }
        case let .Curved(direction):
            switch direction {
            case .North:                            // L  ∧
                directions.append(contentsOf: [.North, .East])
            case .East:                             // L  >
                directions.append(contentsOf: [.East, .South])
            case .South:                            // L  ∨
                directions.append(contentsOf: [.South, .West])
            case .West:                             // L  <
                directions.append(contentsOf: [.North, .West])
            }
        case let .Intersection(direction):
            switch direction {
            case .North:                            // ⊤
                directions.append(contentsOf: [.East, .South, .West])
            case .East:                             // ⊣
                directions.append(contentsOf: [.North, .South, .West])
            case .South:                            // ⊥
                directions.append(contentsOf: [.North, .East, .West])
            case .West:                             // ⊢
                directions.append(contentsOf: [.North, .East, .South])
            }
        }
        
        return directions
    }
    
    var description: String {
        switch self {
        case .None:
            return "x"
        case .Cross:
            return "+"
        case let .Linear(orientation):
            switch orientation {
            case .Horizontal:
                return "-"
            case .Vertical:
                return "|"
            }
        case let .Curved(direction):
            switch direction {
            case .North:
                return "∧"
            case .East:
                return ">"
            case .South:
                return "∨"
            case .West:
                return "<"
            }
        case let .Intersection(direction):
            switch direction {
            case .North:
                return "⊤"
            case .East:
                return "⊣"
            case .South:
                return "⊥"
            case .West:
                return "⊢"
            }
        }
    }
    
    // Custom Encode / Decode
    // Enum with Associated Values Cannot Have a Raw Value and cannot be auto Codable
    
    struct BoxStruct : Codable {
        let type: BoxType
        let orientation: Orientation?
        let direction: Direction?
    }
    
    enum DecodeError : Error {
        case MissingOrientation
        case MissingDirection
    }
    
    init(from decoder: Decoder) throws {
        let boxStruct = try BoxStruct(from: decoder)
        
        switch boxStruct.type {
        case .None:
            self = Box.None
        case .Cross:
            self = Box.Cross
        case .Linear:
            if let o = boxStruct.orientation {
                self = Box.Linear(orientation: o)
            }
            else {
                throw DecodeError.MissingOrientation
            }
        case .Curved:
            if let d = boxStruct.direction {
                self = Box.Curved(direction: d)
            }
            else {
                throw DecodeError.MissingDirection
            }
        case .Intersection:
            if let d = boxStruct.direction {
                self = Box.Intersection(direction: d)
            }
            else {
                throw DecodeError.MissingDirection
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var type: BoxType
        var orientation: Orientation?
        var direction: Direction?
        
        switch self {
        case .None:
            type = .None
        case .Cross:
            type = .Cross
        case let .Linear(o):
            type = .Linear
            orientation = o
        case let .Curved(d):
            type = .Curved
            direction = d
        case let .Intersection(d):
            type = .Intersection
            direction = d
        }

        try BoxStruct(type: type, orientation: orientation, direction: direction).encode(to: encoder)
    }
}

struct Block : Codable, Hashable, Equatable {
    let row: Int
    let col: Int
    let width: Int
    let heigth: Int
    
    func containRowCol(rowcol: (Int, Int)) -> Bool {
        return (rowcol.0 >= row && rowcol.1 >= col && rowcol.0 < row + heigth && rowcol.1 < col + width)
    }
}

struct TableGraph : CustomStringConvertible, Codable {
    var rows: Int
    var columns: Int
    internal var boxes: [Box]
    internal var movableBlocks: Set<Block>
    internal var nonMovableBlocks: Set<Block>
    internal var edges: [[Int]]

    private enum CodingKeys: String, CodingKey {
        case rows
        case columns
        case boxes
        case movableBlocks
        case nonMovableBlocks
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        boxes = try container.decode([Box].self, forKey: .boxes)
        movableBlocks = try container.decode(Set<Block>.self, forKey: .movableBlocks)
        nonMovableBlocks = try container.decode(Set<Block>.self, forKey: .nonMovableBlocks)
        rows = try container.decode(Int.self, forKey: .rows)
        columns = try container.decode(Int.self, forKey: .columns)
        edges = [[Int]](repeating: [Int](), count: rows * columns)
        forceReloadAllEdges()
    }
    
    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        boxes = [Box](repeating: Box.None, count: rows * columns)
        movableBlocks = Set<Block>()
        nonMovableBlocks = Set<Block>()
        edges = [[Int]](repeating: [Int](), count: rows * columns)
        forceReloadAllEdges()
    }

    mutating func forceReloadAllEdges() {
        edges = [[Int]](repeating: [Int](), count: rows * columns)
        var pos = 0
        
        for box in boxes {
            for outputDirection in box.directions {
                var _next: (Int) -> Int?
                var expectedDirection: Direction
                
                switch outputDirection {
                case .North:
                    _next = _north
                    expectedDirection = .South
                case .East:
                    _next = _east
                    expectedDirection = .West
                case .South:
                    _next = _south
                    expectedDirection = .North
                case .West:
                    _next = _west
                    expectedDirection = .East
                }

                if let next = _next(pos) {
                    for inputDirection in boxes[next].directions {
                        if inputDirection == expectedDirection {
                            edges[pos].append(next)
                            break
                        }
                    }
                }
            }
            
            pos += 1
        }
    }
    
    //TODO: FEATURE: Replace nil with the opposite to let the Shortest Path Algorithm (AI) shortcuts outside the inner of the tablegraph
    internal func _north(pos: Int) -> Int? {
        return pos - columns >= 0 ? pos - columns : nil
    }
    internal func _east(pos: Int) -> Int? {
        return pos % columns < columns - 1 ? pos + 1 : nil
    }
    internal func _south(pos: Int) -> Int? {
        return pos + columns < (rows*columns) ? pos + columns : nil
    }
    internal func _west(pos: Int) -> Int? {
        return pos % columns > 0 ? pos - 1 : nil
    }
    
    
    var description: String {
        var descriptionTable = String()
        var col = 0
        
        for box in boxes {
            descriptionTable.append(box.description)
            col += 1
            if col >= columns {
                descriptionTable.append("\n")
                col = 0
            }
        }
        
        return descriptionTable
    }
    
    subscript(row: Int, column: Int) -> Box {
        get {
            return boxes[(row * columns) + column]
        }
        set (newBox) {
            boxes[(row * columns) + column] = newBox
        }
    }

    subscript(pos: Int) -> Box {
        get {
            return boxes[pos]
        }
        set (newBox) {
            boxes[pos] = newBox
        }
    }

    mutating func addMovableBlock(block: Block) {
        movableBlocks.insert(block)
    }
    
    mutating func addNonMovableBlock(block: Block) {
        nonMovableBlocks.insert(block)
    }

    mutating func rotate(row: Int, col: Int, rotation: Rotation) {
        return self.rotate(rowcol: (row, col), rotation: rotation)
    }

    mutating func rotate(pos: Int, rotation: Rotation) {
        return self.rotate(rowcol: (pos / rows, pos % columns), rotation: rotation)
    }

    mutating func rotate(rowcol: (Int, Int), rotation: Rotation) {
        boxes[(rowcol.0 * columns) + rowcol.1].rotate(rotation)
        forceReloadAllEdges() //TODO: OPTIMIZE _forceReloadEdge(row: rowcol.0, col: rowcol.1)
    }
    
    mutating func move(row: Int, col: Int, direction: Direction) -> Bool {
        return self.move(rowcol: (row, col), direction: direction)
    }

    mutating func move(pos: Int, direction: Direction) -> Bool {
        return self.move(rowcol: (pos / rows, pos % columns), direction: direction)
    }
    
    mutating func move(rowcol: (Int, Int), direction: Direction) -> Bool {
        let allRowColToMoveArray = _getAllRowColToMoveArray(rowcol: rowcol, direction: direction)
        let blocksToMoveSet = _getAllBlocksToMove(rowcolArray: allRowColToMoveArray)

        var from = 0, to = 0

        switch direction {
        case .North, .South:
            from = rowcol.1
            to = rowcol.1
            for block in blocksToMoveSet {
                from = min(from, block.col)
                to = max(to, block.col + block.width - 1)
            }
        case .East, .West:
            from = rowcol.0
            to = rowcol.0
            for block in blocksToMoveSet {
                from = min(from, block.row)
                to = max(to, block.row + block.heigth - 1)
            }
        }
        
        var allMovable = true
        for i in from...to {
            if _isNonMovable(rowOrCol: i, direction: direction) {
                allMovable = false
                break
            }
        }

        if allMovable {
            for i in from...to {
                _moveEntireRowOrCol(rowOrCol: i, direction: direction)
            }
            
            forceReloadAllEdges()
            return true
        }
        
        return false
    }

    mutating func shortestPath(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int) -> [Direction]? {
        return self.shortestPath(fromRowCol: (fromRow, fromCol), toRowCol: (toRow, toCol))
    }
    
    mutating func shortestPath(fromPos: Int, toPos: Int) -> [Direction]? {
        struct Path {
            var directions: [Direction]
            var pos: Int
        }
        
        var visited = [Bool](repeating: false, count: rows * columns)
        var queue = [Path]()
        
        queue.append(Path(directions: [Direction](), pos: fromPos))
        
        while !queue.isEmpty {
            let currentPath = queue.removeFirst()
            visited[currentPath.pos] = true
            
            if currentPath.pos == toPos {
                return currentPath.directions
            }
            
            for direction in boxes[currentPath.pos].directions {
                var _next: (Int) -> Int?
                var expectedDirection: Direction
                
                switch direction {
                case .North:
                    _next = _north
                    expectedDirection = .South
                case .East:
                    _next = _east
                    expectedDirection = .West
                case .South:
                    _next = _south
                    expectedDirection = .North
                case .West:
                    _next = _west
                    expectedDirection = .East
                }
                
                if let next = _next(currentPath.pos), !visited[next] {
                    for inputDirection in boxes[next].directions {
                        if inputDirection == expectedDirection {
                            var directions = currentPath.directions
                            directions.append(inputDirection)
                            queue.append(Path(directions: directions, pos: next))
                            break
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    mutating func shortestPath(fromRowCol: (Int, Int), toRowCol: (Int, Int)) -> [Direction]? {
        return self.shortestPath(fromPos: fromRowCol.1 + (fromRowCol.0 * columns), toPos: toRowCol.1 + (toRowCol.0 * columns))
    }
    
    internal mutating func _moveEntireRowOrCol(rowOrCol: Int, direction: Direction) {
        var temp: Box!
        var start = 0
        var end = 0
        var increment = 0

        switch direction {
        case .North:
            start = rowOrCol
            temp = boxes[start]
            end = rows - 1
            increment = columns
        case .South:
            start = rowOrCol + ((rows-1) * columns)
            temp = boxes[start]
            end = rows - 1
            increment = -columns
        case .East:
            start = (rowOrCol * columns) + (columns-1)
            temp = boxes[start]
            end = columns - 1
            increment = -1
        case .West:
            start = rowOrCol * columns
            temp = boxes[start]
            end = columns - 1
            increment = 1
        }
        
        for _ in 0..<end {
            let next = start + increment
            boxes[start] = boxes[next]
            start = next
        }
        
        boxes[start] = temp
    }

    internal func _getAllRowColToMoveArray(rowcol: (Int,Int), direction: Direction) -> [(Int,Int)] {
        var allRowColArray = [(Int,Int)]()

        switch direction {
        case .North, .South:
            for i in 0..<rows {
                allRowColArray.append((i, rowcol.1))
            }
        case .East, .West:
            for i in 0..<columns {
                allRowColArray.append((rowcol.0, i))
            }
        }
        
        return allRowColArray
    }
    
    internal func _getAllBlocksToMove(rowcolArray: [(Int,Int)]) -> Set<Block> {
        var blocksToMoveSet = Set<Block>()
        
        for block in movableBlocks {
            for rowcol in rowcolArray {
                if block.containRowCol(rowcol: rowcol) {
                    blocksToMoveSet.insert(block)
                    break
                }
            }
        }
        
        return blocksToMoveSet
    }
    
    internal func  _isNonMovable(rowOrCol: Int, direction: Direction) -> Bool {
        for block in nonMovableBlocks {
            switch direction {
            case .North, .South:
                for i in 0..<rows {
                    if block.containRowCol(rowcol: (i, rowOrCol)) {
                        return true
                    }
                }
            case .East, .West:
                for i in 0..<columns {
                    if block.containRowCol(rowcol: (rowOrCol, i)) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
}



//var b = Box.Cross
//b.rotate(.Left)
//b = .Linear(orientation: .Horizontal)
//b.rotate(.Left)
//b = .Curved(direction: .North)
//b.rotate(.Left)
//b = .Intersection(direction: .North)
//b.rotate(.Left)

var t = TableGraph(rows: 5, columns: 5)
//print(t.description)

//t[1,2]
//t[1,2] = Box.Linear(orientation: .Horizontal)
//t[1,2]?.rotate(.Left)
//t[1,2]
//t.addBlock(block: Block(row: 0, col: 0, width: 3, heigth: 3))
//print(t.description)


////NORTH - SOUTH
//t[0,2] = Box.Intersection(direction: .North)
//t[1,2] = Box.Intersection(direction: .South)
//t[2,2] = Box.Linear(orientation: .Horizontal)
//t[3,2] = Box.Intersection(direction: .East)
//t[4,2] = Box.Intersection(direction: .West)
//print(t.description)
//t.move(rowcol: (1, 2), direction: .South)
//print(t.description)

//EAST - WEST
t[2,0] = Box.Intersection(direction: .North)
t[2,1] = Box.Intersection(direction: .South)
t[2,2] = Box.Linear(orientation: .Horizontal)
t[2,3] = Box.Intersection(direction: .East)
t[2,4] = Box.Intersection(direction: .West)
print(t.description)
//t.move(rowcol: (2, 2), direction: .East)
t.addMovableBlock(block: Block(row: 1, col: 2, width: 3, heigth: 3))
t.addNonMovableBlock(block: Block(row: 4, col: 2, width: 1, heigth: 1))
t.move(rowcol: (1, 2), direction: .East)
print(t.description)

print(t.shortestPath(fromRowCol: (2, 0), toRowCol: (2, 4)))
print("")

//t.move(rowcol: (3, 3), direction: .North)
//print(t.description)

let data = try JSONEncoder().encode(t)
let string = String(data: data, encoding: .utf8)!
print(string)

let t2 = try JSONDecoder().decode(TableGraph.self, from: data)
print(t2.description)

print(t2[10])
print(t2.edges[10])
print(t2[11])
print(t2.edges[11])
print(t2[12])
print(t2.edges[12])
