import AppKit
import CoreGraphics

func createIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // 1. Background macOS Squircle Tile
    let cornerRadius = size * 0.2237 // Standard Apple squircle radius
    let inset = size * 0.08
    let tileRect = rect.insetBy(dx: inset, dy: inset)
    let tilePath = CGPath(roundedRect: tileRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Outer subtle shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.03), blur: size * 0.06, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.35))
    ctx.addPath(tilePath)
    ctx.setFillColor(CGColor(red: 0.05, green: 0.08, blue: 0.14, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // Tile Gradient (Dark modern blue)
    ctx.saveGState()
    ctx.addPath(tilePath)
    ctx.clip()

    let colors = [
        CGColor(red: 0.08, green: 0.12, blue: 0.22, alpha: 1.0),
        CGColor(red: 0.04, green: 0.06, blue: 0.12, alpha: 1.0)
    ] as CFArray
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: tileRect.midX, y: tileRect.maxY), end: CGPoint(x: tileRect.midX, y: tileRect.minY), options: [])
    }

    // Border highlight
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.12))
    ctx.setLineWidth(size * 0.01)
    ctx.addPath(tilePath)
    ctx.strokePath()
    ctx.restoreGState()

    // 2. Glowing Capsule (BluePill) in center
    ctx.saveGState()
    ctx.translateBy(x: rect.midX, y: rect.midY)
    ctx.rotate(by: -35.0 * .pi / 180.0)

    let pillWidth: CGFloat = size * 0.44
    let pillHeight: CGFloat = size * 0.22
    let pillRect = CGRect(x: -pillWidth / 2, y: -pillHeight / 2, width: pillWidth, height: pillHeight)
    let pillRadius = pillHeight / 2
    let pillPath = CGPath(roundedRect: pillRect, cornerWidth: pillRadius, cornerHeight: pillRadius, transform: nil)

    // Pill Drop Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.02), blur: size * 0.05, color: CGColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 0.5))
    ctx.addPath(pillPath)
    ctx.setFillColor(CGColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // Left Half (Bright Cyan / Electric Blue)
    ctx.saveGState()
    ctx.addPath(pillPath)
    ctx.clip()

    let leftHalfRect = CGRect(x: pillRect.minX, y: pillRect.minY, width: pillWidth / 2, height: pillHeight)
    let rightHalfRect = CGRect(x: 0, y: pillRect.minY, width: pillWidth / 2, height: pillHeight)

    // Draw Left Half (Vibrant Blue)
    let blueColors = [
        CGColor(red: 0.15, green: 0.65, blue: 1.0, alpha: 1.0),
        CGColor(red: 0.0, green: 0.42, blue: 0.95, alpha: 1.0)
    ] as CFArray
    if let blueGrad = CGGradient(colorsSpace: colorSpace, colors: blueColors, locations: [0.0, 1.0]) {
        ctx.saveGState()
        ctx.clip(to: leftHalfRect)
        ctx.drawLinearGradient(blueGrad, start: CGPoint(x: leftHalfRect.midX, y: leftHalfRect.maxY), end: CGPoint(x: leftHalfRect.midX, y: leftHalfRect.minY), options: [])
        ctx.restoreGState()
    }

    // Draw Right Half (Clean White / Platinum)
    let whiteColors = [
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
        CGColor(red: 0.82, green: 0.86, blue: 0.92, alpha: 1.0)
    ] as CFArray
    if let whiteGrad = CGGradient(colorsSpace: colorSpace, colors: whiteColors, locations: [0.0, 1.0]) {
        ctx.saveGState()
        ctx.clip(to: rightHalfRect)
        ctx.drawLinearGradient(whiteGrad, start: CGPoint(x: rightHalfRect.midX, y: rightHalfRect.maxY), end: CGPoint(x: rightHalfRect.midX, y: rightHalfRect.minY), options: [])
        ctx.restoreGState()
    }

    // Center divider seam
    ctx.setStrokeColor(CGColor(red: 0.1, green: 0.2, blue: 0.35, alpha: 0.3))
    ctx.setLineWidth(size * 0.005)
    ctx.move(to: CGPoint(x: 0, y: pillRect.minY))
    ctx.addLine(to: CGPoint(x: 0, y: pillRect.maxY))
    ctx.strokePath()

    // Top Gloss Highlight
    let highlightRect = CGRect(x: -pillWidth * 0.42, y: pillHeight * 0.1, width: pillWidth * 0.84, height: pillHeight * 0.3)
    let highlightPath = CGPath(roundedRect: highlightRect, cornerWidth: highlightRect.height / 2, cornerHeight: highlightRect.height / 2, transform: nil)
    ctx.addPath(highlightPath)
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.35))
    ctx.fillPath()

    ctx.restoreGState() // End clip pill
    ctx.restoreGState() // End rotate/translate

    image.unlockFocus()
    return image
}

let fileManager = FileManager.default
let iconsetDir = "Resources/AppIcon.iconset"
try? fileManager.removeItem(atPath: iconsetDir)
try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in sizes {
    let img = createIcon(size: size)
    if let tiffData = img.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(iconsetDir)/\(name)"
        try? pngData.write(to: URL(fileURLWithPath: path))
    }
}
print("Generated all icon sizes in \(iconsetDir)")
