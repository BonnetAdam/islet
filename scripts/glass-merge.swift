// swift scripts/glass-merge.swift <window.png> <screen.png>: a capture of the island's window alone keeps its outline and
// shadow but not what shows through its glass, which only the screen has. Inside the island (opaque in the window
// capture) the pixels are taken from the screen capture of the same rectangle; the window capture is rewritten.
import AppKit

func load(_ path: String) -> CGImage {
    let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(source, 0, nil)!
}
func pixels(_ image: CGImage) -> (CGContext, UnsafeMutablePointer<UInt8>) {
    let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return (context, context.data!.assumingMemoryBound(to: UInt8.self))
}
let windowPath = CommandLine.arguments[1]
let window = load(windowPath), screen = load(CommandLine.arguments[2])
guard window.width == screen.width, window.height == screen.height else { fatalError("the two captures differ in size") }
let (context, island) = pixels(window)
// The screen's context owns its pixels: it is kept alive while they are read.
let (screenContext, desk) = pixels(screen)
withExtendedLifetime(screenContext) {
    for i in stride(from: 0, to: window.width * window.height * 4, by: 4) where island[i + 3] == 255 {
        island[i] = desk[i]; island[i + 1] = desk[i + 1]; island[i + 2] = desk[i + 2]
    }
}
try! NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: windowPath))
