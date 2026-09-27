// swift brand/scripts/og-image.swift: the website's link preview, 1280 x 640, in site/assets/brand/og.png.
// Night ground, the coral glow of the notch, the icon and the promise.
import AppKit

func color(_ hex: String, alpha: CGFloat = 1) -> NSColor {
    let value = UInt64(hex.dropFirst(), radix: 16) ?? 0
    return NSColor(srgbRed: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255,
                   blue: CGFloat(value & 0xFF) / 255, alpha: alpha)
}

let width: CGFloat = 1280, height: CGFloat = 640
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(width), pixelsHigh: Int(height), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

color("#0A0A0B").setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()
NSGradient(colors: [color("#FF6A45", alpha: 0.34), color("#FF6A45", alpha: 0)])!
    .draw(fromCenter: NSPoint(x: width / 2, y: height), radius: 0, toCenter: NSPoint(x: width / 2, y: height), radius: 520, options: [])

// The notch at the top edge, with a live activity in its wings.
let notch = NSBezierPath(roundedRect: NSRect(x: width / 2 - 170, y: height - 58, width: 340, height: 80), xRadius: 26, yRadius: 26)
color("#000000").setFill()
notch.fill()
color("#FF7A59").setFill()
NSBezierPath(roundedRect: NSRect(x: width / 2 - 146, y: height - 44, width: 26, height: 26), xRadius: 7, yRadius: 7).fill()
for (index, bar) in [10.0, 18, 13, 22].enumerated() {
    NSBezierPath(roundedRect: NSRect(x: width / 2 + 116 + CGFloat(index) * 8, y: height - 31 - bar / 2, width: 4.5, height: bar), xRadius: 2.25, yRadius: 2.25).fill()
}

let icon = NSImage(contentsOfFile: "brand/icon-1024.png")!
icon.draw(in: NSRect(x: width / 2 - 72, y: 300, width: 144, height: 144))

func centered(_ text: String, font: NSFont, color: NSColor, y: CGFloat) {
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .kern: -font.pointSize * 0.03]
    let size = (text as NSString).size(withAttributes: attributes)
    (text as NSString).draw(at: NSPoint(x: (width - size.width) / 2, y: y), withAttributes: attributes)
}
centered("The notch, made useful.", font: .systemFont(ofSize: 64, weight: .heavy), color: color("#F3EFEC"), y: 190)
centered("Music, AirPods, files, timers and your AI agents. Free and open source for Mac.",
         font: .systemFont(ofSize: 24, weight: .medium), color: color("#9C9690"), y: 138)

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "site/assets/brand/og.png"))
print("site/assets/brand/og.png")
