import AppKit
import SpacebarCore
import SwiftUI
import UniformTypeIdentifiers

/// Squarified treemap (Bruls, Huizing & van Wijk): lays out `values` (largest first) in `rect`,
/// keeping rectangles close to square so their areas are easy to compare.
func squarify(_ values: [Double], in rect: CGRect) -> [CGRect] {
    let total = values.reduce(0, +)
    guard total > 0, rect.width > 0, rect.height > 0 else { return values.map { _ in .zero } }
    let scale = rect.width * rect.height / total
    let areas = values.map { $0 * scale }
    var result: [CGRect] = []
    var remaining = rect
    var row: [Double] = []

    func worst(_ row: [Double], side: Double) -> Double {
        let sum = row.reduce(0, +)
        guard let largest = row.max(), let smallest = row.min(), sum > 0, smallest > 0 else { return .infinity }
        return max(side * side * largest / (sum * sum), sum * sum / (side * side * smallest))
    }

    func place(_ row: [Double]) {
        let sum = row.reduce(0, +)
        if remaining.width >= remaining.height {
            let width = sum / remaining.height
            var y = remaining.minY
            for area in row {
                let height = area / width
                result.append(CGRect(x: remaining.minX, y: y, width: width, height: height))
                y += height
            }
            remaining = CGRect(x: remaining.minX + width, y: remaining.minY,
                               width: max(0, remaining.width - width), height: remaining.height)
        } else {
            let height = sum / remaining.width
            var x = remaining.minX
            for area in row {
                let width = area / height
                result.append(CGRect(x: x, y: remaining.minY, width: width, height: height))
                x += width
            }
            remaining = CGRect(x: remaining.minX, y: remaining.minY + height,
                               width: remaining.width, height: max(0, remaining.height - height))
        }
    }

    var index = 0
    while index < areas.count {
        let side = min(remaining.width, remaining.height)
        let area = areas[index]
        if row.isEmpty || worst(row + [area], side: side) <= worst(row, side: side) {
            row.append(area)
            index += 1
        } else {
            place(row)
            row = []
        }
    }
    if !row.isEmpty { place(row) }
    return result
}

/// What a treemap tile is, for its color. Fixed categorical order (validated for color vision).
enum TileKind: Int, CaseIterable {
    case folder, document, media, archive, app, other

    var name: String {
        switch self {
        case .folder: return "Folders"
        case .document: return "Documents"
        case .media: return "Photos, video & audio"
        case .archive: return "Archives & disk images"
        case .app: return "Apps"
        case .other: return "Other files"
        }
    }

    var color: Color {
        switch self {
        case .folder: return .dynamic(light: 0x2A78D6, dark: 0x3987E5)
        case .document: return .dynamic(light: 0xEB6834, dark: 0xD95926)
        case .media: return .dynamic(light: 0x1BAF7A, dark: 0x199E70)
        case .archive: return .dynamic(light: 0xEDA100, dark: 0xC98500)
        case .app: return .dynamic(light: 0xE87BA4, dark: 0xD55181)
        case .other: return .dynamic(light: 0x8A8985, dark: 0x8F8E88)
        }
    }

    static func of(_ entry: ExplorerModel.Entry) -> TileKind {
        let ext = entry.url.pathExtension.lowercased()
        if ext == "app" { return .app }
        guard let type = UTType(filenameExtension: ext) else { return entry.isFolder ? .folder : .other }
        if type.conforms(to: .image) || type.conforms(to: .audiovisualContent) || type.conforms(to: .audio) { return .media }
        if type.conforms(to: .archive) || type.conforms(to: .diskImage) || ["dmg", "pkg", "xip", "iso"].contains(ext) { return .archive }
        if entry.isFolder { return .folder }
        if type.conforms(to: .pdf) || type.conforms(to: .text) || type.conforms(to: .presentation)
            || type.conforms(to: .spreadsheet) || type.conforms(to: .compositeContent) { return .document }
        return .other
    }
}

struct TreemapView: View {
    @EnvironmentObject private var explorer: ExplorerModel
    /// Tiles beyond this are folded into one "Other" tile so labels stay readable.
    private let maxTiles = 60

    private struct Tile: Identifiable {
        let id: String
        let entry: ExplorerModel.Entry?
        let name: String
        let bytes: Int64
        let kind: TileKind
        var count = 1
    }

    var body: some View {
        let tiles = makeTiles()
        VStack(alignment: .leading, spacing: 8) {
            legend(tiles)
            GeometryReader { geo in
                let frames = squarify(tiles.map { Double($0.bytes) }, in: CGRect(origin: .zero, size: geo.size))
                ZStack(alignment: .topLeading) {
                    ForEach(Array(zip(tiles, frames)), id: \.0.id) { tile, frame in
                        TileView(name: tile.name, bytes: tile.bytes, kind: tile.kind,
                                 isFolder: tile.entry?.isFolder == true, count: tile.count)
                            .frame(width: max(0, frame.width - 2), height: max(0, frame.height - 2))
                            .offset(x: frame.minX + 1, y: frame.minY + 1)
                            .onTapGesture { if let entry = tile.entry, entry.isFolder { explorer.open(entry) } }
                    }
                }
            }
            .overlay {
                if tiles.isEmpty {
                    Text(explorer.loading ? "Measuring…" : "Nothing here takes up space")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
    }

    private func makeTiles() -> [Tile] {
        let measured = explorer.entries.compactMap { entry -> Tile? in
            guard let bytes = explorer.sizes[entry.url]?.allocated, bytes > 0 else { return nil }
            return Tile(id: entry.url.path, entry: entry, name: entry.name, bytes: bytes, kind: TileKind.of(entry))
        }.sorted { $0.bytes > $1.bytes }
        guard measured.count > maxTiles else { return measured }
        let rest = measured.dropFirst(maxTiles - 1)
        var other = Tile(id: "other", entry: nil, name: "\(rest.count) smaller items",
                         bytes: rest.reduce(0) { $0 + $1.bytes }, kind: .other)
        other.count = rest.count
        return Array(measured.prefix(maxTiles - 1)) + [other]
    }

    private func legend(_ tiles: [Tile]) -> some View {
        let present = TileKind.allCases.filter { kind in tiles.contains { $0.kind == kind } }
        return HStack(spacing: 14) {
            ForEach(present, id: \.self) { kind in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2).fill(kind.color).frame(width: 10, height: 10)
                    Text(kind.name).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("Click a folder to open it").font(.caption).foregroundStyle(.tertiary)
        }
    }
}

private struct TileView: View {
    let name: String
    let bytes: Int64
    let kind: TileKind
    let isFolder: Bool
    let count: Int
    @State private var hovering = false

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 4)
                .fill(kind.color.opacity(hovering ? 1 : 0.85))
                .overlay(alignment: .topLeading) {
                    if geo.size.width > 60 && geo.size.height > 30 {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(name).font(.caption.weight(.semibold)).lineLimit(1)
                            if geo.size.height > 44 {
                                Text(ByteFormat.string(bytes)).font(.caption2).monospacedDigit()
                            }
                        }
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 1, y: 0.5)
                        .padding(6)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 4).strokeBorder(.white.opacity(hovering ? 0.8 : 0), lineWidth: 1.5)
                }
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .help("\(name): \(ByteFormat.string(bytes))" + (isFolder ? " · click to open" : ""))
    }
}
