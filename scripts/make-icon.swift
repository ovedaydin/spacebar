// Renders packaging/AppIcon.icns. Run: swift scripts/make-icon.swift
import AppKit

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(px) / 1024
    // macOS icon grid: 824pt rounded square centred in a 1024 canvas.
    let rect = NSRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
    let shape = NSBezierPath(roundedRect: rect, xRadius: 185 * s, yRadius: 185 * s)
    NSGradient(colors: [NSColor(srgbRed: 0.33, green: 0.36, blue: 0.98, alpha: 1),
                        NSColor(srgbRed: 0.10, green: 0.78, blue: 0.86, alpha: 1)])!
        .draw(in: shape, angle: -60)

    // Stacked "storage" bars, last one short: space being freed.
    let widths: [CGFloat] = [560, 560, 300]
    for (i, w) in widths.enumerated() {
        let y = (610 - CGFloat(i) * 150) * s
        let bar = NSBezierPath(roundedRect: NSRect(x: 232 * s, y: y, width: w * s, height: 96 * s),
                               xRadius: 48 * s, yRadius: 48 * s)
        NSColor.white.withAlphaComponent(i == 2 ? 1 : 0.55).setFill()
        bar.fill()
    }
    if let spark = NSImage(systemSymbolName: "sparkle", accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: 200 * s, weight: .bold)
            .applying(.init(paletteColors: [.white]))) {
        spark.draw(in: NSRect(x: 580 * s, y: 270 * s, width: 210 * s, height: 210 * s))
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for base in [16, 32, 128, 256, 512] {
    try render(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try render(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
let out = root.appendingPathComponent("packaging/AppIcon.icns")
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", out.path]
try p.run(); p.waitUntilExit()
print("Wrote \(out.path)")
