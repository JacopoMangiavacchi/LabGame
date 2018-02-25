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
//        X
//        +
//        -|
//        ⊤⊣⊥⊢
//        ∨∧><
        return "-"
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

struct Table : CustomStringConvertible, Codable {
    var rows: Int
    var columns: Int
    var boxes: [Box]
    
    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        boxes = [Box](repeating: Box.Linear(orientation: .Horizontal), count: rows * columns)
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

let data = try JSONEncoder().encode(t)
let string = String(data: data, encoding: .utf8)!
print(string)

let t2 = try JSONDecoder().decode(Table.self, from: data)
print(t2.description)


