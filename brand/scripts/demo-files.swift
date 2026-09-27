// swift brand/scripts/demo-files.swift <folder> <cover.png>: the demo files the website's captures put on the shelf
// (a PDF brief, a photo, a note), and the pieces of macOS the website's scenes use: the system arrow cursor and the
// Finder thumbnail of the brief, as PNG at 2x.
import AppKit
import QuickLookThumbnailing

_ = NSApplication.shared   // NSCursor draws nothing without an application

let folder = URL(fileURLWithPath: CommandLine.arguments[1])
let cover = URL(fileURLWithPath: CommandLine.arguments[2])
try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

// A one-page brief, A4.
let pdfURL = folder.appendingPathComponent("Brief.pdf")
var box = CGRect(x: 0, y: 0, width: 595, height: 842)
let pdf = CGContext(pdfURL as CFURL, mediaBox: &box, nil)!
pdf.beginPDFPage(nil)
NSGraphicsContext.current = NSGraphicsContext(cgContext: pdf, flipped: false)
NSColor.white.setFill(); box.fill()
NSColor(srgbRed: 1, green: 0.478, blue: 0.349, alpha: 1).setFill()
NSRect(x: 0, y: 742, width: 595, height: 100).fill()
("Product brief" as NSString).draw(at: NSPoint(x: 48, y: 776), withAttributes: [.font: NSFont.systemFont(ofSize: 34, weight: .bold), .foregroundColor: NSColor.white])
("Autumn launch · Draft 3" as NSString).draw(at: NSPoint(x: 48, y: 700), withAttributes: [.font: NSFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: NSColor.black])
for line in 0..<14 {
    NSColor(white: 0.82, alpha: 1).setFill()
    NSRect(x: 48, y: 660 - CGFloat(line) * 26, width: line % 4 == 3 ? 300 : 499, height: 9).fill()
}
pdf.endPDFPage()
pdf.closePDF()

try? FileManager.default.removeItem(at: folder.appendingPathComponent("Sunset.png"))
try FileManager.default.copyItem(at: cover, to: folder.appendingPathComponent("Sunset.png"))
try "Launch checklist\n\n- Final copy\n- Screenshots\n- Press kit\n".write(to: folder.appendingPathComponent("Notes.txt"), atomically: true, encoding: .utf8)

func writePNG(_ image: NSImage, _ path: String, size: CGFloat) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size * 2), pixelsHigh: Int(size * 2), bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let aspect = image.size.width / max(image.size.height, 1)
    let w = aspect >= 1 ? size : size * aspect, h = aspect >= 1 ? size / aspect : size
    image.draw(in: NSRect(x: (size - w) / 2, y: (size - h) / 2, width: w, height: h))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

// The arrow cursor, at the size macOS draws it (its image is 17 x 23 points with its shadow).
let arrow = NSCursor.arrow.image
let cursorRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(arrow.size.width * 2), pixelsHigh: Int(arrow.size.height * 2), bitsPerSample: 8,
                                 samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
cursorRep.size = arrow.size
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: cursorRep)
arrow.draw(in: NSRect(origin: .zero, size: arrow.size))
NSGraphicsContext.restoreGraphicsState()
try! cursorRep.representation(using: .png, properties: [:])!.write(to: folder.deletingLastPathComponent().appendingPathComponent("cursor-arrow.png"))
print("cursor", arrow.size, "hotspot", NSCursor.arrow.hotSpot)

// The Finder thumbnail of the brief, as it sits on a desktop.
let done = DispatchSemaphore(value: 0)
let request = QLThumbnailGenerator.Request(fileAt: pdfURL, size: CGSize(width: 64, height: 64), scale: 2, representationTypes: .thumbnail)
QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, error in
    if let image = representation?.nsImage {
        writePNG(image, folder.deletingLastPathComponent().appendingPathComponent("brief-icon.png").path, size: 64)
    } else {
        print("no thumbnail: \(String(describing: error))")
    }
    done.signal()
}
done.wait()
print(folder.path)
