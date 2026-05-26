import CoreGraphics
import Foundation

/// Parses an SVG `d`-attribute string into a CGPath.
///
/// Supports the subset used by the Wikipedia cell symbol library after svgo
/// optimization: `M/m`, `L/l`, `C/c`, `Z/z`. That covers every path in the
/// hematopoiesis library — no arcs, quadratics, or shorthand commands appear.
/// A survey of the source: 3254 `c`, 2612 `l`, 2105 `m`, 2044 `z`, nothing else.
enum SVGPathParser {

    static func parse(_ d: String) -> CGPath {
        let path = CGMutablePath()
        let scalars = Array(d.unicodeScalars)
        var i = 0
        let n = scalars.count
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var cmd: UnicodeScalar = " "
        var firstMove = true

        @inline(__always)
        func skipSeparators() {
            while i < n {
                let c = scalars[i]
                if c == " " || c == "\n" || c == "\t" || c == "\r" || c == "," {
                    i += 1
                } else { break }
            }
        }

        @inline(__always)
        func peekIsNumberStart() -> Bool {
            guard i < n else { return false }
            let c = scalars[i]
            return c == "-" || c == "+" || c == "."
                || (c.value >= 0x30 && c.value <= 0x39)  // 0-9
        }

        func readNumber() -> Double? {
            skipSeparators()
            guard i < n else { return nil }
            let start = i
            // optional sign
            if scalars[i] == "+" || scalars[i] == "-" { i += 1 }
            var sawDigit = false
            var sawDot = false
            while i < n {
                let c = scalars[i]
                if c.value >= 0x30 && c.value <= 0x39 { sawDigit = true; i += 1 }
                else if c == "." && !sawDot { sawDot = true; i += 1 }
                else { break }
            }
            if i < n, scalars[i] == "e" || scalars[i] == "E" {
                i += 1
                if i < n, scalars[i] == "+" || scalars[i] == "-" { i += 1 }
                while i < n, scalars[i].value >= 0x30 && scalars[i].value <= 0x39 {
                    i += 1
                }
            }
            guard sawDigit else { i = start; return nil }
            var s = ""
            s.reserveCapacity(i - start)
            for k in start..<i { s.unicodeScalars.append(scalars[k]) }
            return Double(s)
        }

        func readPoint() -> CGPoint? {
            guard let x = readNumber(), let y = readNumber() else { return nil }
            return CGPoint(x: x, y: y)
        }

        while i < n {
            skipSeparators()
            guard i < n else { break }
            let c = scalars[i]
            if (c.value >= 0x41 && c.value <= 0x5A) || (c.value >= 0x61 && c.value <= 0x7A) {
                cmd = c
                i += 1
            }

            switch cmd {
            case "M":
                guard let p = readPoint() else { return path }
                path.move(to: p)
                current = p; subpathStart = p; firstMove = false
                while peekIsNumberStart() {
                    guard let np = readPoint() else { break }
                    path.addLine(to: np); current = np
                }

            case "m":
                let p: CGPoint
                if firstMove {
                    // SVG spec: first relative m at start of path is absolute.
                    guard let abs = readPoint() else { return path }
                    p = abs; firstMove = false
                } else {
                    guard let rel = readPoint() else { return path }
                    p = CGPoint(x: current.x + rel.x, y: current.y + rel.y)
                }
                path.move(to: p)
                current = p; subpathStart = p
                while peekIsNumberStart() {
                    guard let rel = readPoint() else { break }
                    let np = CGPoint(x: current.x + rel.x, y: current.y + rel.y)
                    path.addLine(to: np); current = np
                }

            case "L":
                while peekIsNumberStart() {
                    guard let p = readPoint() else { break }
                    path.addLine(to: p); current = p
                }

            case "l":
                while peekIsNumberStart() {
                    guard let rel = readPoint() else { break }
                    let p = CGPoint(x: current.x + rel.x, y: current.y + rel.y)
                    path.addLine(to: p); current = p
                }

            case "C":
                while peekIsNumberStart() {
                    guard let c1 = readPoint(),
                          let c2 = readPoint(),
                          let p  = readPoint() else { break }
                    path.addCurve(to: p, control1: c1, control2: c2)
                    current = p
                }

            case "c":
                while peekIsNumberStart() {
                    guard let c1r = readPoint(),
                          let c2r = readPoint(),
                          let pr  = readPoint() else { break }
                    let c1 = CGPoint(x: current.x + c1r.x, y: current.y + c1r.y)
                    let c2 = CGPoint(x: current.x + c2r.x, y: current.y + c2r.y)
                    let p  = CGPoint(x: current.x + pr.x,  y: current.y + pr.y)
                    path.addCurve(to: p, control1: c1, control2: c2)
                    current = p
                }

            case "Z", "z":
                path.closeSubpath()
                current = subpathStart

            default:
                // Unknown command — consume one number to avoid an infinite loop.
                _ = readNumber()
            }
        }
        return path
    }
}
