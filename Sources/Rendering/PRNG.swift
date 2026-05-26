import Foundation

/// Seeded pseudo-random generator. Mirrors `pseudoRandom` / `nextSeed` from the
/// HTML reference exactly, so a given seed produces the same wallpaper as the
/// web version. `random(_:)` is a pure hash of its argument; `next()` walks an
/// internal counter the way the JS global `_seedCounter` did.
final class PRNG {
    private let baseSeed: Double
    private var counter: Double = 0

    init(seed: Int) {
        baseSeed = Double(seed)
    }

    /// Pure deterministic hash → value in 0..<1.
    func random(_ seed: Double) -> Double {
        let s = seed * 0.7891 + 13.37
        let x = sin(s * 12.9898
                    + cos(s * 78.233) * 43.7
                    + sin(s * 31.41) * 17.3) * 43758.5453
        return x - x.rounded(.down)
    }

    /// Advances the counter and returns the next seed value.
    func next() -> Double {
        counter += 1.7321
        return baseSeed + counter
    }

    func reset() {
        counter = 0
    }
}
