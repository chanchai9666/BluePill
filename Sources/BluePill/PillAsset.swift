import AppKit
import SwiftUI

public enum PillAsset {
    /// Renders a crisp blue & white capsule pill image with Retina support via drawingHandler
    public static func createPillImage(size: CGFloat, isActive: Bool = true) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            let alpha: CGFloat = isActive ? 1.0 : 0.85

            ctx.saveGState()
            ctx.translateBy(x: rect.midX, y: rect.midY)
            ctx.rotate(by: -35.0 * .pi / 180.0)

            let pillWidth: CGFloat = size * 0.82
            let pillHeight: CGFloat = size * 0.42
            let pillRect = CGRect(x: -pillWidth / 2, y: -pillHeight / 2, width: pillWidth, height: pillHeight)
            let pillRadius = pillHeight / 2
            let pillPath = CGPath(roundedRect: pillRect, cornerWidth: pillRadius, cornerHeight: pillRadius, transform: nil)

            // Glow aura when active
            if isActive {
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: size * 0.22, color: CGColor(red: 0.1, green: 0.65, blue: 1.0, alpha: 0.9))
                ctx.addPath(pillPath)
                ctx.setFillColor(CGColor(red: 0.05, green: 0.5, blue: 1.0, alpha: 1.0))
                ctx.fillPath()
                ctx.restoreGState()
            }

            // Clip capsule interior
            ctx.saveGState()
            ctx.addPath(pillPath)
            ctx.clip()

            let leftHalfRect = CGRect(x: pillRect.minX, y: pillRect.minY, width: pillWidth / 2, height: pillHeight)
            let rightHalfRect = CGRect(x: 0, y: pillRect.minY, width: pillWidth / 2, height: pillHeight)
            let colorSpace = CGColorSpaceCreateDeviceRGB()

            // Left Half: Vibrant Royal Blue
            let blueColors = [
                CGColor(red: 0.25, green: 0.75, blue: 1.0, alpha: alpha),
                CGColor(red: 0.0, green: 0.45, blue: 0.95, alpha: alpha)
            ] as CFArray
            if let blueGrad = CGGradient(colorsSpace: colorSpace, colors: blueColors, locations: [0.0, 1.0]) {
                ctx.saveGState()
                ctx.clip(to: leftHalfRect)
                ctx.drawLinearGradient(blueGrad, start: CGPoint(x: leftHalfRect.midX, y: leftHalfRect.maxY), end: CGPoint(x: leftHalfRect.midX, y: leftHalfRect.minY), options: [])
                ctx.restoreGState()
            }

            // Right Half: Crisp Solid White
            let whiteColors = [
                CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: alpha),
                CGColor(red: 0.88, green: 0.92, blue: 0.96, alpha: alpha)
            ] as CFArray
            if let whiteGrad = CGGradient(colorsSpace: colorSpace, colors: whiteColors, locations: [0.0, 1.0]) {
                ctx.saveGState()
                ctx.clip(to: rightHalfRect)
                ctx.drawLinearGradient(whiteGrad, start: CGPoint(x: rightHalfRect.midX, y: rightHalfRect.maxY), end: CGPoint(x: rightHalfRect.midX, y: rightHalfRect.minY), options: [])
                ctx.restoreGState()
            }

            // Center dividing seam
            ctx.setStrokeColor(CGColor(red: 0.1, green: 0.25, blue: 0.4, alpha: 0.4 * alpha))
            ctx.setLineWidth(max(1.0, size * 0.03))
            ctx.move(to: CGPoint(x: 0, y: pillRect.minY))
            ctx.addLine(to: CGPoint(x: 0, y: pillRect.maxY))
            ctx.strokePath()

            // Top glossy highlight reflection
            let highlightRect = CGRect(x: -pillWidth * 0.4, y: pillHeight * 0.08, width: pillWidth * 0.8, height: pillHeight * 0.35)
            let highlightPath = CGPath(roundedRect: highlightRect, cornerWidth: highlightRect.height / 2, cornerHeight: highlightRect.height / 2, transform: nil)
            ctx.addPath(highlightPath)
            ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.55 * alpha))
            ctx.fillPath()

            ctx.restoreGState() // End clip interior

            // Crisp outer border contour
            ctx.setStrokeColor(CGColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.35 * alpha))
            ctx.setLineWidth(max(0.75, size * 0.02))
            ctx.addPath(pillPath)
            ctx.strokePath()

            ctx.restoreGState() // End rotate/translate

            return true
        }

        image.isTemplate = false
        return image
    }

    /// Optimized 18x18 icon for the macOS menu bar
    public static func menuBarIcon(isActive: Bool) -> NSImage {
        let img = createPillImage(size: 18, isActive: isActive)
        img.isTemplate = false
        return img
    }
}
