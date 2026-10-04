import Foundation
import SpacebarCore

/// "Free up 20 GB": the safest suggestions first, until the target is reached.
struct FreeUpPlan {
    enum Tier: Int, Comparable {
        case safe = 1, rebuilt, glance
        static func < (a: Tier, b: Tier) -> Bool { a.rawValue < b.rawValue }

        var label: String {
            switch self {
            case .safe: return String(localized: "Safe: rebuilt automatically")
            case .rebuilt: return String(localized: "Rebuilt or downloaded again when needed")
            case .glance: return String(localized: "Worth a glance first")
            }
        }
    }

    struct Step: Identifiable {
        var id: String { category.id }
        let category: CleanCategory
        let tier: Tier
        let items: [CleanItem]
        var bytes: Int64 { items.reduce(0) { $0 + $1.size } }
    }

    static let tiers: [String: Tier] = [
        "caches": .safe, "logs": .safe, "xcode": .safe, "devcaches": .safe, "trash": .safe,
        "browsers": .rebuilt, "simulators": .rebuilt, "devtools": .rebuilt, "projects": .rebuilt, "icloud": .rebuilt,
        "leftovers": .glance, "forgotten": .glance, "duplicates": .glance, "installers": .glance, "archives": .glance,
    ]

    let steps: [Step]
    let target: Int64
    var total: Int64 { steps.reduce(0) { $0 + $1.bytes } }
    var reachesTarget: Bool { total >= target }

    /// Takes whole categories in order (safest, then largest) until the target is met. Only items
    /// Spacebar suggests; rules count as "rebuilt" since the user wrote them.
    static func make(target: Int64, categories: [CleanCategory], items: (CleanCategory) -> [CleanItem]) -> FreeUpPlan {
        let candidates = categories.compactMap { category -> Step? in
            guard let tier = tiers[category.id] ?? (category.group == .rules ? .rebuilt : nil) else { return nil }
            let chosen = items(category)
            return chosen.isEmpty ? nil : Step(category: category, tier: tier, items: chosen)
        }
        .sorted { ($0.tier, -$0.bytes) < ($1.tier, -$1.bytes) }
        var steps: [Step] = []
        var total: Int64 = 0
        for step in candidates where total < target {
            steps.append(step)
            total += step.bytes
        }
        return FreeUpPlan(steps: steps, target: target)
    }
}
