import AppKit
// swift brand/scripts/demo-cover.swift <out.png>: the album cover of the demo track in the website captures,
// dusk over layered hills.
let s: CGFloat = 800
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(s), pixelsHigh: Int(s), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor { NSColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a) }
NSGradient(colors: [c(255, 176, 120), c(238, 96, 102), c(96, 46, 120), c(30, 20, 60)], atLocations: [0, 0.35, 0.7, 1], colorSpace: .sRGB)!
    .draw(in: NSRect(x: 0, y: 0, width: s, height: s), angle: -90)
NSGradient(colors: [c(255, 236, 200, 0.95), c(255, 200, 150, 0)])!.draw(fromCenter: NSPoint(x: 520, y: 430), radius: 0, toCenter: NSPoint(x: 520, y: 430), radius: 260, options: [])
c(255, 240, 215).setFill(); NSBezierPath(ovalIn: NSRect(x: 450, y: 360, width: 140, height: 140)).fill()
func hill(_ base: CGFloat, _ amp: CGFloat, _ phase: CGFloat, _ color: NSColor) {
    let p = NSBezierPath(); p.move(to: NSPoint(x: 0, y: 0))
    for x in stride(from: 0, through: s, by: 8) { p.line(to: NSPoint(x: x, y: base + amp * sin(x / 130 + phase) + amp * 0.4 * sin(x / 47 + phase * 2))) }
    p.line(to: NSPoint(x: s, y: 0)); p.close(); color.setFill(); p.fill()
}
hill(330, 34, 0.3, c(120, 50, 110, 0.85)); hill(250, 42, 1.7, c(70, 30, 90, 0.92)); hill(160, 30, 3.1, c(35, 18, 55)); hill(80, 22, 4.4, c(18, 10, 32))
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
