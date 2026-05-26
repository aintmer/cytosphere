import CoreGraphics
import Foundation

/// Loads the Wikipedia cell symbol library from the bundled JSON and parses
/// every SVG d-string into a CGPath once. Later renders just stroke/fill the
/// prebuilt paths.
///
/// Source artwork: A. Rad and Mikael Häggström, "Hematopoiesis_simple.svg",
/// Wikimedia Commons, CC-BY-SA 3.0
/// (https://commons.wikimedia.org/wiki/File:Hematopoiesis_simple.svg).
/// Attribution string lives in the JSON's `_attribution` field and is read out
/// here so an About screen / settings can surface it later.
final class HematopoiesisLibrary {
    static let shared = HematopoiesisLibrary()

    struct BakedPath {
        let cgPath: CGPath
        let fill: RGBA
        let transform: CGAffineTransform
    }

    struct Cell {
        let width: Double
        let height: Double
        let paths: [BakedPath]
    }

    private(set) var cells: [String: Cell] = [:]
    let attribution: String

    private init() {
        guard let url = Bundle.main.url(forResource: "HematopoiesisSymbols",
                                        withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            attribution = ""
            return
        }
        attribution = (json["_attribution"] as? String) ?? ""

        guard let raw = json["cells"] as? [String: [String: Any]] else { return }
        for (id, entry) in raw {
            guard let w = entry["w"] as? Double,
                  let h = entry["h"] as? Double,
                  let rawPaths = entry["paths"] as? [[String: Any]]
            else { continue }

            var baked: [BakedPath] = []
            baked.reserveCapacity(rawPaths.count)
            for p in rawPaths {
                guard let d = p["d"] as? String,
                      let fillStr = p["f"] as? String,
                      let m = p["m"] as? [Double], m.count == 6
                else { continue }
                let t = CGAffineTransform(
                    a: CGFloat(m[0]), b: CGFloat(m[1]),
                    c: CGFloat(m[2]), d: CGFloat(m[3]),
                    tx: CGFloat(m[4]), ty: CGFloat(m[5])
                )
                baked.append(BakedPath(
                    cgPath: SVGPathParser.parse(d),
                    fill: HematopoiesisLibrary.parseColor(fillStr),
                    transform: t
                ))
            }
            cells[id] = Cell(width: w, height: h, paths: baked)
        }
    }

    private static func parseColor(_ s: String) -> RGBA {
        if s.hasPrefix("#") {
            return RGBA(hex: s)
        }
        if s.hasPrefix("rgb") {
            let nums = s.split(whereSeparator: {
                !($0.isNumber || $0 == ".")
            }).compactMap { Double($0) }
            if nums.count >= 3 {
                return RGBA(r: nums[0], g: nums[1], b: nums[2])
            }
        }
        return RGBA(r: 0, g: 0, b: 0)
    }
}
