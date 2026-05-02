import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: render_icon.swift <output.png>\n", stderr)
    exit(64)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let pixelSize = 1024

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixelSize,
    pixelsHigh: pixelSize,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("failed to create bitmap\n", stderr)
    exit(1)
}

bitmap.size = NSSize(width: pixelSize, height: pixelSize)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

let bounds = NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
NSColor.clear.setFill()
bounds.fill()

let bodyRect = bounds.insetBy(dx: 166, dy: 130)
let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 118, yRadius: 118)
NSColor(calibratedWhite: 0.10, alpha: 1).setFill()
bodyPath.fill()
NSColor(calibratedWhite: 0.91, alpha: 1).setStroke()
bodyPath.lineWidth = 34
bodyPath.stroke()

let dividerY = bodyRect.maxY - 250
let dividerPath = NSBezierPath()
dividerPath.move(to: NSPoint(x: bodyRect.minX + 62, y: dividerY))
dividerPath.line(to: NSPoint(x: bodyRect.maxX - 62, y: dividerY))
NSColor(calibratedWhite: 0.91, alpha: 0.72).setStroke()
dividerPath.lineWidth = 22
dividerPath.lineCapStyle = .round
dividerPath.stroke()

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center

let weekdayAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 118, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.92, alpha: 1),
    .paragraphStyle: paragraph
]

let dayAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedDigitSystemFont(ofSize: 304, weight: .bold),
    .foregroundColor: NSColor(calibratedWhite: 0.98, alpha: 1),
    .paragraphStyle: paragraph
]

"FRI".draw(
    in: NSRect(x: bodyRect.minX, y: dividerY + 44, width: bodyRect.width, height: 145),
    withAttributes: weekdayAttributes
)
"1".draw(
    in: NSRect(x: bodyRect.minX, y: bodyRect.minY + 108, width: bodyRect.width, height: 330),
    withAttributes: dayAttributes
)

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [.compressionFactor: 0.95]) else {
    fputs("failed to render icon\n", stderr)
    exit(1)
}

try png.write(to: outputURL)
