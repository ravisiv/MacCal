import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: render_icon.swift <output.png>\n", stderr)
    exit(64)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let bounds = NSRect(origin: .zero, size: size)
NSColor.clear.setFill()
bounds.fill()

let bodyRect = bounds.insetBy(dx: 170, dy: 135)
let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 120, yRadius: 120)
NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
bodyPath.fill()
NSColor(calibratedWhite: 0.88, alpha: 1).setStroke()
bodyPath.lineWidth = 34
bodyPath.stroke()

let dividerY = bodyRect.maxY - 250
let dividerPath = NSBezierPath()
dividerPath.move(to: NSPoint(x: bodyRect.minX + 58, y: dividerY))
dividerPath.line(to: NSPoint(x: bodyRect.maxX - 58, y: dividerY))
NSColor(calibratedWhite: 0.88, alpha: 0.7).setStroke()
dividerPath.lineWidth = 24
dividerPath.stroke()

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center

let weekdayAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 120, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.9, alpha: 1),
    .paragraphStyle: paragraph
]

let dayAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedDigitSystemFont(ofSize: 300, weight: .bold),
    .foregroundColor: NSColor(calibratedWhite: 0.98, alpha: 1),
    .paragraphStyle: paragraph
]

"FRI".draw(in: NSRect(x: bodyRect.minX, y: dividerY + 42, width: bodyRect.width, height: 150), withAttributes: weekdayAttributes)
"1".draw(in: NSRect(x: bodyRect.minX, y: bodyRect.minY + 105, width: bodyRect.width, height: 330), withAttributes: dayAttributes)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("failed to render icon\n", stderr)
    exit(1)
}

try png.write(to: outputURL)
