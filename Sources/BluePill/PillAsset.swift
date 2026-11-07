import AppKit
import SwiftUI

public enum PillAsset {
    /// Renders a crisp blue & white capsule pill image at any specified size
    public static func createPillImage(size: CGFloat, isActive: Bool = true) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        let alpha: CGFloat = isActive ? 1.0 : 0.45

        ctx.saveGState()
        ctx.translateBy(x: rect.midX, y: rect.midY)
        ctx.rotate(by: -35.0 * .pi / 180.0)

        let pillWidth: CGFloat = size * 0.78
        let pillHeight: CGFloat = size * 0.39
        let pillRect = CGRect(x: -pillWidth / 2, y: -pillHeight / 2, width: pillWidth, height: pillHeight)
        let pillRadius = pillHeight / 2
        let pillPath = CGPath(roundedRect: pillRect, cornerWidth: pillRadius, cornerHeight: pillRadius, transform: nil)

        // Subtle shadow / glow when active
        if isActive {
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: -1), blur: size * 0.1, color: CGColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 0.6))
            ctx.addPath(pillPath)
            ctx.setFillColor(CGColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 0.8))
            ctx.fillPath()
            ctx.restoreGState()
        }

        // Clip capsule
        ctx.saveGState()
        ctx.addPath(pillPath)
        ctx.clip()

        let leftHalfRect = CGRect(x: pillRect.minX, y: pillRect.minY, width: pillWidth / 2, height: pillHeight)
        let rightHalfRect = CGRect(x: 0, y: pillRect.minY, width: pillWidth / 2, height: pillHeight)

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Left Half (Vibrant Royal Blue)
        let blueColors = [
            CGColor(red: 0.12, green: 0.65, blue: 1.0, alpha: alpha),
            CGColor(red: 0.0, green: 0.45, blue: 0.95, alpha: alpha)
        ] as CFArray
        if let blueGrad = CGGradient(colorsSpace: colorSpace, colors: blueColors, locations: [0.0, 1.0]) {
            ctx.saveGState()
            ctx.clip(to: leftHalfRect)
            ctx.drawLinearGradient(blueGrad, start: CGPoint(x: leftHalfRect.midX, y: leftHalfRect.maxY), end: CGPoint(x: leftHalfRect.midX, y: leftHalfRect.minY), options: [])
            ctx.restoreGState()
        }

        // Right Half (Clean White / Platinum)
        let whiteColors = [
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: alpha),
            CGColor(red: 0.85, green: 0.88, blue: 0.94, alpha: alpha)
        ] as CFArray
        if let whiteGrad = CGGradient(colorsSpace: colorSpace, colors: whiteColors, locations: [0.0, 1.0]) {
            ctx.saveGState()
            ctx.clip(to: rightHalfRect)
            ctx.drawLinearGradient(whiteGrad, start: CGPoint(x: rightHalfRect.midX, y: rightHalfRect.maxY), end: CGPoint(x: rightHalfRect.midX, y: rightHalfRect.minY), options: [])
            ctx.restoreGState()
        }

        // Center seam
        ctx.setStrokeColor(CGColor(red: 0.1, green: 0.2, blue: 0.35, alpha: 0.3 * alpha))
        ctx.setLineWidth(max(1.0, size * 0.02))
        ctx.move(to: CGPoint(x: 0, y: pillRect.minY))
        ctx.addLine(to: CGPoint(x: 0, y: pillRect.maxY))
        ctx.strokePath()

        // Top glossy reflection
        let highlightRect = CGRect(x: -pillWidth * 0.42, y: pillHeight * 0.1, width: pillWidth * 0.84, height: pillHeight * 0.3)
        let highlightPath = CGPath(roundedRect: highlightRect, cornerWidth: highlightRect.height / 2, cornerHeight: highlightRect.height / 2, transform: nil)
        ctx.addPath(highlightPath)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.45 * alpha))
        ctx.fillPath()

        ctx.restoreGState() // End clip
        ctx.restoreGState() // End rotate

        image.unlockFocus()
        return image
    }

    /// Optimized 18x18 icon for the macOS menu bar
    public static func menuBarIcon(isActive: Bool) -> NSImage {
        let img = createPillImage(size: 18, isActive: isActive)
        img.isTemplate = false // Keep its vibrant blue & white colors!
        return img
    }
}
