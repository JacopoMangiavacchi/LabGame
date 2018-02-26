import Foundation

enum Rotation : Int {
    case Right, Left
}

protocol Rotate {
    mutating func rotate(_ rotation: Rotation)
}

enum Orientation : Int, Rotate, Codable  {
    case Horizontal, Vertical // 2
    
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

enum Box : Rotate, CustomStringConvertible, Codable {
    case None                               // X
    case Cross                              // +
    case Linear(orientation: Orientation)   // - |
    case Curved(direction: Direction)       // L  ∨∧><
    case Intersection(direction: Direction) // T  ⊤⊣⊥⊢
    
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
    
    var description: String {
        switch self {
        case .None:
            return "X"
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
                return "∨"
            case .East:
                return "∧"
            case .South:
                return ">"
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
        let rawValue: Int
        let orientation: Orientation?
        let direction: Direction?
    }
    
    enum DecodeError : Error {
        case WrongRawValue
        case MissingOrientation
        case MissingDirection
    }
    
    init(from decoder: Decoder) throws {
        let boxStruct = try BoxStruct(from: decoder)
        
        switch boxStruct.rawValue {
        case 0:
            self = Box.None
        case 1:
            self = Box.Cross
        case 2:
            if let o = boxStruct.orientation {
                self = Box.Linear(orientation: o)
            }
            else {
                throw DecodeError.MissingOrientation
            }
        case 3:
            if let d = boxStruct.direction {
                self = Box.Curved(direction: d)
            }
            else {
                throw DecodeError.MissingDirection
            }
        case 4:
            if let d = boxStruct.direction {
                self = Box.Intersection(direction: d)
            }
            else {
                throw DecodeError.MissingDirection
            }
        default:
            throw DecodeError.WrongRawValue
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var rawValue = 0
        var orientation: Orientation?
        var direction: Direction?
        
        switch self {
        case .None:
            rawValue = 0
        case .Cross:
            rawValue = 1
        case let .Linear(o):
            rawValue = 2
            orientation = o
        case let .Curved(d):
            rawValue = 3
            direction = d
        case let .Intersection(d):
            rawValue = 4
            direction = d
        }

        try BoxStruct(rawValue: rawValue, orientation: orientation, direction: direction).encode(to: encoder)
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

struct Table : CustomStringConvertible, Codable {
    var rows: Int
    var columns: Int
    internal var boxes: [Box]
    internal var blocks: Set<Block>

    
    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        boxes = [Box](repeating: Box.None, count: rows * columns)
        blocks = Set<Block>()
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
    
    subscript(row: Int, column: Int) -> Box? {
        get {
            return boxes[(row * columns) + column]
        }
        set (newBox) {
            if let n = newBox {
                boxes[(row * columns) + column] = n
            }
            else {
                boxes[(row * columns) + column] = Box.None
            }
        }
    }
    
    mutating func addBlock(block: Block) {
        blocks.insert(block)
    }
    
    mutating func move(row: Int, col: Int, direction: Direction) -> Int {
        return self.move(rowcol: (row, col), direction: direction)
    }

    mutating func move(rowcol: (Int, Int), direction: Direction) -> Int {
        return self.move(rowcolArray: [rowcol], direction: direction)
    }

    mutating func move(rowcolArray: [(Int,Int)], direction: Direction) -> Int {
        let cleanedRowColArray = _getCleanRowColArray(rowcolArray: rowcolArray, direction: direction)
        let allRowColToMoveArray = _getAllRowColToMoveArray(rowcolArray: cleanedRowColArray, direction: direction)
        let blocksToMoveSet = _getAllBlocksToMove(rowcolArray: allRowColToMoveArray)
        
        print(blocksToMoveSet)
        
        
        
        
        
        
        
        
        return 0
    }
    
    internal func _getCleanRowColArray(rowcolArray: [(Int,Int)], direction: Direction) -> [(Int,Int)] {
        var cleanedRowColArray = [(Int,Int)]()
        
        for rowcol in rowcolArray {
            var found = false
            
            for existingRowCol in cleanedRowColArray {
                switch direction {
                case .North, .South:
                    if rowcol.1 == existingRowCol.1 {
                        found = true
                    }
                case .East, .West:
                    if rowcol.0 == existingRowCol.0 {
                        found = true
                    }
                }
                
                if found {
                    break
                }
            }
            
            if !found {
                cleanedRowColArray.append(rowcol)
            }
        }
        
        return cleanedRowColArray
    }
    
    internal func _getAllRowColToMoveArray(rowcolArray: [(Int,Int)], direction: Direction) -> [(Int,Int)] {
        var allRowColArray = [(Int,Int)]()

        for rowcol in rowcolArray {
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
        }
        
        return allRowColArray
    }
    
    internal func _getAllBlocksToMove(rowcolArray: [(Int,Int)]) -> Set<Block> {
        var blocksToMoveSet = Set<Block>()
        
        for block in blocks {
            for rowcol in rowcolArray {
                if block.containRowCol(rowcol: rowcol) {
                    blocksToMoveSet.insert(block)
                    break
                }
            }
        }
        
        return blocksToMoveSet
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

var t = Table(rows: 5, columns: 5)
print(t.description)

t[1,2]
t[1,2] = Box.Linear(orientation: .Horizontal)
t[1,2]?.rotate(.Left)
t[1,2]
t.addBlock(block: Block(row: 0, col: 0, width: 3, heigth: 3))
t.move(rowcolArray: [(0, 3), (3, 2)], direction: .North)

let data = try JSONEncoder().encode(t)
let string = String(data: data, encoding: .utf8)!
print(string)

let t2 = try JSONDecoder().decode(Table.self, from: data)
print(t2.description)


