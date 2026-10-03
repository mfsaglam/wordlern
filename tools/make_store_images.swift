#!/usr/bin/env swift

// Composes the App Store Connect marketing images: a raw simulator capture on the
// icon's near-black background, with one caption above it.
//
//   swift tools/make_store_images.swift                  # reads ~/Desktop, writes build/store
//   swift tools/make_store_images.swift --in ~/captures  # raws somewhere else
//
// Raw captures and finished images are both build inputs, not source — neither is
// committed. The raws are the twelve ⌘S screenshots described in docs/RELEASE.md,
// named <screen>_<iphone|ipad>_raw.png, at the exact sizes App Store Connect wants
// (1320×2868 and 2064×2752). The canvas is the capture's own size, so nothing is
// resampled except by the one uniform scale that makes room for the caption.

import AppKit
import CoreText
import Foundation

// MARK: - The set

/// Captions are docs/RELEASE.md's table. Order is the order they appear in the listing.
let screens: [(file: String, caption: String)] = [
    ("card_faceup", "The words that actually come up"),
    ("card_facedown", "See it used, not just translated"),
    ("overview", "Know exactly where you stand"),
    ("end_session", "Small sessions, every day"),
    ("how_it_works", "Spaced repetition, not willpower"),
    ("widget", "Progress on your home screen"),
]

struct Device {
    let name: String
    /// Which raw capture feeds this set — `<screen>_<source>_raw.png`.
    let source: String
    /// The size of that raw capture, and so the size it must be to be used unresampled.
    let capture: CGSize
    /// The canvas App Store Connect wants for this slot. Need not match the capture.
    let canvas: CGSize
    /// The display's own corner radius in capture pixels: 55pt at @3x, 30pt at @2x.
    let cornerRadius: CGFloat
}

let iPhoneCapture = CGSize(width: 1320, height: 2868)

// Connect's iPhone slots take 6.9" or 6.5", and which one a listing is asked for depends
// on what the published version already has. 1.0 shipped 6.5", so the 6.9" set alone was
// rejected at upload: *"Screenshots dimensions should be: 1242 × 2688px … 1284 × 2778px"*.
// Both sets are built from the one 6.9" capture, so there is nothing to re-shoot.
let devices = [
    Device(name: "iphone-6-9", source: "iphone", capture: iPhoneCapture,
           canvas: CGSize(width: 1320, height: 2868), cornerRadius: 165),
    Device(name: "iphone-6-5", source: "iphone", capture: iPhoneCapture,
           canvas: CGSize(width: 1284, height: 2778), cornerRadius: 165),
    Device(name: "ipad", source: "ipad", capture: CGSize(width: 2064, height: 2752),
           canvas: CGSize(width: 2064, height: 2752), cornerRadius: 60),
]

// MARK: - Design
//
// Every measurement is a fraction of the canvas height, so the iPhone and iPad sets
// are the same composition at two sizes rather than two compositions.

let background = "#15181D"  // the icon's background
let captionColour = "#F7F5F0"  // the icon's glyph

let fontFraction: CGFloat = 0.0375  // caption size
let lineSpacing: CGFloat = 1.20  // × the caption size
let topPadFraction: CGFloat = 0.032  // canvas top to the first line's ascender
let gapFraction: CGFloat = 0.030  // last caption line to the capture
let bottomFraction: CGFloat = 0.035  // capture to the canvas bottom
let captureWidthFraction: CGFloat = 0.82  // the capture never grows past this
let textWidthFraction: CGFloat = 0.82  // the caption wraps inside this

// The caption band always reserves two lines, whether the caption needs them or not.
// That keeps the first baseline on the same pixel row in all six images, which is the
// thing the eye picks up when they scroll past as a row of thumbnails.
let reservedLines: CGFloat = 2

// MARK: - Helpers

func colour(_ hex: String) -> CGColor {
    var value: UInt64 = 0
    Scanner(string: String(hex.dropFirst())).scanHexInt64(&value)
    return CGColor(red: CGFloat((value >> 16) & 0xFF) / 255,
                   green: CGFloat((value >> 8) & 0xFF) / 255,
                   blue: CGFloat(value & 0xFF) / 255,
                   alpha: 1)
}

func load(_ url: URL) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("could not read \(url.path)")
    }
    return image
}

func line(_ text: String, font: CTFont) -> CTLine {
    CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [
        .font: font,
        .foregroundColor: NSColor(cgColor: colour(captionColour))!,
        .kern: CTFontGetSize(font) * -0.01,
    ]))
}

func width(_ text: String, font: CTFont) -> CGFloat {
    CGFloat(CTLineGetTypographicBounds(line(text, font: font), nil, nil, nil))
}

/// One line if it fits, otherwise the two-line break that leaves the lines closest in
/// width. Balanced beats greedy here: greedy wrapping leaves a stub second line, which
/// looks like an accident rather than a decision.
func wrap(_ caption: String, font: CTFont, maxWidth: CGFloat) -> [String] {
    if width(caption, font: font) <= maxWidth { return [caption] }

    let words = caption.split(separator: " ").map(String.init)
    var best: (lines: [String], widest: CGFloat)?
    for split in 1..<words.count {
        let first = words[..<split].joined(separator: " ")
        let second = words[split...].joined(separator: " ")
        let widest = max(width(first, font: font), width(second, font: font))
        guard widest <= maxWidth else { continue }
        if best == nil || widest < best!.widest {
            best = ([first, second], widest)
        }
    }
    guard let best else { fatalError("\"\(caption)\" does not fit in two lines") }
    return best.lines
}

// MARK: - Composition

func compose(capture: CGImage, caption: String, device: Device) -> Data {
    let width = device.canvas.width
    let height = device.canvas.height

    precondition(CGFloat(capture.width) == device.capture.width
                 && CGFloat(capture.height) == device.capture.height,
                 "capture is \(capture.width)×\(capture.height), expected "
                 + "\(Int(device.capture.width))×\(Int(device.capture.height))")

    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let context = CGContext(data: nil,
                                  width: Int(width),
                                  height: Int(height),
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: space,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        fatalError("could not make a \(Int(width))×\(Int(height)) context")
    }

    context.setFillColor(colour(background))
    context.fill(CGRect(origin: .zero, size: device.canvas))

    let fontSize = height * fontFraction
    let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold) as CTFont
    let lineHeight = fontSize * lineSpacing
    let topPad = height * topPadFraction
    let band = topPad + lineHeight * reservedLines + height * gapFraction

    // The capture keeps its aspect ratio: one scale, applied to both axes, small enough
    // to clear the band and the bottom margin and to stay inside the side margins. On a
    // canvas the same shape as the capture the height is what binds; on the 6.5" canvas,
    // which is slightly wider for its height, it still is — but only just, so the width
    // is checked rather than assumed.
    let scale = min((height - band - height * bottomFraction) / device.capture.height,
                    width * captureWidthFraction / device.capture.width)
    let drawn = CGSize(width: device.capture.width * scale, height: device.capture.height * scale)
    let frame = CGRect(x: (width - drawn.width) / 2,
                       y: height - band - drawn.height,
                       width: drawn.width,
                       height: drawn.height)

    context.saveGState()
    let radius = device.cornerRadius * scale
    context.addPath(CGPath(roundedRect: frame, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.clip()
    context.interpolationQuality = .high
    context.draw(capture, in: frame)
    context.restoreGState()

    // y-up, so a baseline measured from the top of the canvas is height - that.
    let ascent = CTFontGetAscent(font)
    for (index, text) in wrap(caption, font: font, maxWidth: width * textWidthFraction).enumerated() {
        let drawn = line(text, font: font)
        let advance = CGFloat(CTLineGetTypographicBounds(drawn, nil, nil, nil))
        context.textPosition = CGPoint(x: (width - advance) / 2,
                                       y: height - (topPad + ascent + lineHeight * CGFloat(index)))
        CTLineDraw(drawn, context)
    }

    guard let image = context.makeImage() else { fatalError("no image") }
    guard let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
        fatalError("no png")
    }
    return data
}

/// A thumbnail of the finished image, at roughly the width App Store shows in its
/// scrolling row. If the caption cannot be read here, it cannot be read in the store.
func thumbnail(_ png: Data, width target: CGFloat) -> Data {
    guard let source = CGImageSourceCreateWithData(png as CFData, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("could not re-read the composed image")
    }
    let height = target * CGFloat(image.height) / CGFloat(image.width)
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let context = CGContext(data: nil,
                                  width: Int(target),
                                  height: Int(height),
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: space,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        fatalError("could not make the thumbnail context")
    }
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: target, height: height))
    guard let scaled = context.makeImage(),
          let data = NSBitmapImageRep(cgImage: scaled).representation(using: .png, properties: [:]) else {
        fatalError("no thumbnail png")
    }
    return data
}

// MARK: - Run

let arguments = CommandLine.arguments
var inputDirectory = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop")
if let index = arguments.firstIndex(of: "--in"), let path = arguments.dropFirst(index + 1).first {
    inputDirectory = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("build/store")
let proofs = output.appendingPathComponent("proof")
try! FileManager.default.createDirectory(at: proofs, withIntermediateDirectories: true)

for device in devices {
    for (number, screen) in screens.enumerated() {
        let name = "\(screen.file)_\(device.source)_raw.png"
        let source = inputDirectory.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: source.path) else {
            fatalError("missing capture: \(source.path)")
        }

        let png = compose(capture: load(source), caption: screen.caption, device: device)
        let stem = String(format: "%02d-%@-%@", number + 1, screen.file.replacingOccurrences(of: "_", with: "-"), device.name)
        try! png.write(to: output.appendingPathComponent("\(stem).png"))
        try! thumbnail(png, width: 300).write(to: proofs.appendingPathComponent("\(stem).png"))
        print("wrote build/store/\(stem).png")
    }
}

print("thumbnail proofs in build/store/proof/")
