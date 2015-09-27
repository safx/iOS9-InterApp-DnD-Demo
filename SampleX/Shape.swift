//
//  Shape.swift
//  ios9-dnd-demo
//
//  Created by Safx Developer on 2015/09/27.
//
//

import UIKit

enum Shape {
    case Rectangle(pos: CGPoint, size: CGSize, color: UIColor)
    case Ellipse(pos: CGPoint, size: CGSize, color: UIColor)

    static func createShape(type: String, size: CGSize, color: String) -> Shape? {
        let pos = CGPointMake(-10000, -10000) // FIXME
        let color = Shape.stringToColor(color: color)
        switch type {
        case "rectangle": return .Rectangle(pos: pos, size: size, color: color)
        case "ellipse":   return .Ellipse  (pos: pos, size: size, color: color)
        default: return nil
        }
    }

    mutating func changePosition(pos: CGPoint) {
        switch self {
        case .Rectangle(let (_, size, color)):
            self = .Rectangle(pos: pos, size: size, color: color)
        case .Ellipse(let (_, size, color)):
            self = .Ellipse(pos: pos, size: size, color: color)
        }
    }

    static func colorToString(color: UIColor) -> String {
        var c = [CGFloat](count: 4, repeatedValue: 0.0)
        color.getRed(&c[0], green: &c[1], blue: &c[2], alpha: &c[3])
        return c[0...2].map{String(format:"%02X", Int(255 * $0))}.joinWithSeparator("")
    }

    static func stringToColor(color c: String) -> UIColor {
        precondition(c.characters.count == 6)
        let cs = [
            c[Range(start: c.startIndex, end: c.startIndex.advancedBy(2))],
            c[Range(start: c.startIndex.advancedBy(2), end: c.startIndex.advancedBy(4))],
            c[Range(start: c.startIndex.advancedBy(4), end: c.startIndex.advancedBy(6))]
        ].flatMap{ Int($0, radix: 16) }
        assert(cs.count == 3)
        let z = cs.map{ CGFloat($0) }
        return UIColor(red: z[0], green: z[1], blue: z[2], alpha: CGFloat(1.0))
    }

    var position: CGPoint {
        switch self {
        case .Rectangle(let (p, _, _)): return p
        case .Ellipse(let (p, _, _)): return p
        }
    }

    var string: String {
        switch self {
        case .Rectangle(let (_, s, c)): return "rectangle,\(Int(s.width)),\(Int(s.height)),\(Shape.colorToString(c))"
        case .Ellipse(let (_, s, c)):   return "ellipse,\(Int(s.width)),\(Int(s.height)),\(Shape.colorToString(c))"
        }
    }
}

protocol Drawable {
    func draw()
}

extension Shape: Drawable {
    func draw() {
        color.setFill()
        path.fill()
    }

    private var color: UIColor {
        switch self {
        case .Rectangle(let (_, _, color)): return color
        case .Ellipse(let (_, _, color)): return color
        }
    }

    private var path: UIBezierPath {
        switch self {
        case .Rectangle(let (pos, size, _)):
            return UIBezierPath(rect: CGRect(origin: pos, size: size))
        case .Ellipse(let (pos, size, _)):
            return UIBezierPath(ovalInRect: CGRect(origin: pos, size: size))
        }
    }
}

extension Shape {
    func isClicked(pos: CGPoint) -> Bool {
        switch self {
        case .Rectangle(let (p, s, _)):
            let rect = CGRect(origin: p, size: s)
            return CGRectContainsPoint(rect, pos)
        case .Ellipse(let (p, s, _)):
            let rw = s.width / 2
            let rh = s.height / 2
            let c = CGPointMake(p.x + rw, p.y + rh)
            let x = pos.x - c.x
            let y = pos.y - c.y
            let w = rw * rw
            let h = rh * rh
            return (x * x) / w + (y * y) / h <= 1.0
        }
    }
}
