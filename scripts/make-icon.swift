// scripts/make-icon.swift: draws Islet's app icon and writes the asset catalog's PNGs.
// Usage: swift scripts/make-icon.swift App/Assets.xcassets/AppIcon.appiconset
import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.appiconset")
try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

/// The island: the notch outline, ears and continuous corners, as the app draws it.
func islandPath(width: CGFloat, height: CGFloat, ear: CGFloat, radius: CGFloat, centerX: CGFloat, top: CGFloat) -> CGPath {
    let left = centerX - width / 2, right = centerX + width / 2, bottom = top - height
    let reach = min(radius * 1.28, height - ear, width / 2), handle = reach * 0.36
    let path = CGMutablePath()
    path.move(to: CGPoint(x: left - ear, y: top))
    path.addQuadCurve(to: CGPoint(x: left, y: top - ear), control: CGPoint(x: left, y: top))
    path.addLine(to: CGPoint(x: left, y: bottom + reach))
    path.addCurve(to: CGPoint(x: left + reach, y: bottom), control1: CGPoint(x: left, y: bottom + handle), control2: CGPoint(x: left + handle, y: bottom))
    path.addLine(to: CGPoint(x: right - reach, y: bottom))
    path.addCurve(to: CGPoint(x: right, y: bottom + reach), control1: CGPoint(x: right - handle, y: bottom), control2: CGPoint(x: right, y: bottom + handle))
    path.addLine(to: CGPoint(x: right, y: top - ear))
    path.addQuadCurve(to: CGPoint(x: right + ear, y: top), control: CGPoint(x: right, y: top))
    path.closeSubpath()
    return path
}

func render(_ size: Int) -> Data {
    let s = CGFloat(size)
    let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.scaleBy(x: s / 1024, y: s / 1024)
    // macOS icon grid: an 824 point rounded square centred in 1024, with a soft shadow.
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: color(0x000000, 0.35))
    context.addPath(shape)
    context.setFillColor(color(0x05080A))
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(shape)
    context.clip()
    // The screen: a lagoon at dawn, bright at the top where the island hangs.
    let screen = CGGradient(colorsSpace: nil, colors: [color(0x6AF2D4), color(0x1FB095), color(0x0C5A5E), color(0x072A30)] as CFArray, locations: [0, 0.3, 0.72, 1])!
    context.drawLinearGradient(screen, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
    // A soft reflection on the water, low in the frame.
    let shimmer = CGGradient(colorsSpace: nil, colors: [color(0x9CFFE6, 0.28), color(0x9CFFE6, 0)] as CFArray, locations: [0, 1])!
    context.drawRadialGradient(shimmer, startCenter: CGPoint(x: 512, y: 300), startRadius: 0, endCenter: CGPoint(x: 512, y: 300), endRadius: 360, options: [])
    // The island, black, hanging from the top edge of the screen, with its shadow.
    let island = islandPath(width: 384, height: 190, ear: 30, radius: 88, centerX: 512, top: 924)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -18), blur: 40, color: color(0x02181B, 0.55))
    context.addPath(island)
    context.setFillColor(color(0x000000))
    context.fillPath()
    context.restoreGState()
    // A live activity inside: a cover on the left, dancing bars on the right.
    let cover = CGPath(roundedRect: CGRect(x: 364, y: 776, width: 80, height: 80), cornerWidth: 22, cornerHeight: 22, transform: nil)
    context.saveGState()
    context.addPath(cover)
    context.clip()
    let art = CGGradient(colorsSpace: nil, colors: [color(0xFF6B8B), color(0x6A3DF0)] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(art, start: CGPoint(x: 364, y: 856), end: CGPoint(x: 444, y: 776), options: [])
    context.restoreGState()
    context.setFillColor(color(0x4FE3C1))
    for (index, height) in [CGFloat(38), 74, 52, 82].enumerated() {
        let x = 578 + CGFloat(index) * 24
        context.addPath(CGPath(roundedRect: CGRect(x: x, y: 816 - height / 2, width: 14, height: height), cornerWidth: 7.5, cornerHeight: 7.5, transform: nil))
        context.fillPath()
    }
    context.restoreGState()

    let image = context.makeImage()!
    return NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
}

var entries: [[String: String]] = []
for (points, scales) in [(16, [1, 2]), (32, [1, 2]), (128, [1, 2]), (256, [1, 2]), (512, [1, 2])] {
    for scale in scales {
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        try! render(points * scale).write(to: output.appendingPathComponent(name))
        entries.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": entries, "info": ["author": "xcode", "version": 1]]
try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("Contents.json"))
try! render(1024).write(to: output.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("brand/icon-1024.png"))
print("wrote \(output.path)")
