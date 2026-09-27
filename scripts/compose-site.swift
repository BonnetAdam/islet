// swift scripts/compose-site.swift <desktop.png> <shots folder>: the website's figures, each a real capture of Islet
// (from scripts/capture-site.sh) laid on the top of a real macOS desktop, both at 2x.
// Output: <shots folder>/figures/<name>.png, converted to WebP by the caller.
import AppKit

/// Pixels exactly as stored in the file: NSImage would hand back a copy rendered for the screen.
func load(_ path: String) -> CGImage? {
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

let desktopPath = CommandLine.arguments[1]
guard let desktop = load(desktopPath) else { fatalError("no desktop at \(desktopPath)") }
let shots = CommandLine.arguments[2], out = "\(shots)/figures"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)

/// The top of the desktop, `width` x `height` pixels around the notch, with the capture hanging from the top edge.
func figure(_ shot: String, width: Int = 1760, height: Int = 700, name: String) {
    guard let island = load("\(shots)/\(shot).png") else {
        print("missing \(shot)"); return
    }
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let x = (desktop.width - width) / 2
    let crop = desktop.cropping(to: CGRect(x: x, y: 0, width: width, height: height))!
    context.draw(crop, in: CGRect(x: 0, y: 0, width: width, height: height))
    // The notch itself, under every capture: 185 x 32 points at the top of a 14-inch MacBook Pro.
    context.setFillColor(CGColor(gray: 0, alpha: 1))
    context.addPath(CGPath(roundedRect: CGRect(x: width / 2 - 185, y: height - 64 - 24, width: 370, height: 64 + 24), cornerWidth: 20, cornerHeight: 20, transform: nil))
    context.fillPath()
    context.draw(island, in: CGRect(x: (width - island.width) / 2, y: height - island.height, width: island.width, height: island.height))
    let image = context.makeImage()!
    let rep = NSBitmapImageRep(cgImage: image)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name).png"))
    print("  \(name)")
}

figure("music-compact", name: "glance")
figure("music-open", name: "open")
figure("airpods-pro", name: "airpods-pro")
figure("airpods-max", name: "airpods-max")
figure("agent-request", name: "agent")

// At rest: the notch alone.
do {
    let width = 1760, height = 700
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.draw(desktop.cropping(to: CGRect(x: (desktop.width - width) / 2, y: 0, width: width, height: height))!, in: CGRect(x: 0, y: 0, width: width, height: height))
    context.setFillColor(CGColor(gray: 0, alpha: 1))
    context.addPath(CGPath(roundedRect: CGRect(x: width / 2 - 185, y: height - 64 - 24, width: 370, height: 64 + 24), cornerWidth: 20, cornerHeight: 20, transform: nil))
    context.fillPath()
    try! NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: "\(out)/rest.png"))
    print("  rest")
}
