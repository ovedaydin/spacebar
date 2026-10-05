// Fails if a window snapshot looks blank: few distinct colors below the toolbar.
// Usage: swift scripts/check-snapshot.swift shot1.png shot2.png …
import CoreGraphics
import Foundation
import ImageIO

var failed = false
for path in CommandLine.arguments.dropFirst() {
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
          let data = image.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else {
        print("FAIL \(path): missing or unreadable"); failed = true; continue
    }
    let width = image.width, height = image.height, row = image.bytesPerRow, step = image.bitsPerPixel / 8
    var colors = Set<UInt32>()
    // A grid of samples in the content area (skip the toolbar at the top).
    for y in stride(from: height / 8, to: height, by: max(1, height / 60)) {
        for x in stride(from: 0, to: width, by: max(1, width / 80)) {
            let p = bytes + y * row + x * step
            // Quantize so anti-aliasing noise doesn't count as content.
            colors.insert(UInt32(p[0] >> 4) << 8 | UInt32(p[1] >> 4) << 4 | UInt32(p[2] >> 4))
        }
    }
    let ok = colors.count >= 8 // blank windows score 3-4; real pages, even empty ones, 14+
    print("\(ok ? "ok  " : "FAIL") \(URL(fileURLWithPath: path).lastPathComponent): \(colors.count) distinct colors")
    if !ok { failed = true }
}
exit(failed ? 1 : 0)
