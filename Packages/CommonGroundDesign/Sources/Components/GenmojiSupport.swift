import UIKit

/// Utilities for storing and rendering Apple Genmoji (`NSAdaptiveImageGlyph`) outside rich text.
public enum GenmojiSupport {
    public static var isSupported: Bool {
        if #available(iOS 18.0, *) {
            return true
        }
        return false
    }

    public static func extractImageContent(from attributed: NSAttributedString) -> Data? {
        guard isSupported else { return nil }
        guard #available(iOS 18.0, *) else { return nil }
        var found: Data?
        attributed.enumerateAttribute(
            .adaptiveImageGlyph,
            in: NSRange(location: 0, length: attributed.length)
        ) { value, _, stop in
            guard let glyph = value as? NSAdaptiveImageGlyph else { return }
            found = glyph.imageContent
            stop.pointee = true
        }
        return found
    }

    public static func renderImage(from data: Data, size: CGFloat) -> UIImage? {
        guard isSupported, !data.isEmpty else { return nil }
        guard #available(iOS 18.0, *) else { return nil }
        let glyph = NSAdaptiveImageGlyph(imageContent: data)
        let font = UIFont.systemFont(ofSize: size * 0.9)
        let attributed = NSAttributedString(adaptiveImageGlyph: glyph, attributes: [.font: font])
        let textSize = attributed.size()
        let canvas = CGSize(width: size, height: size)

        return UIGraphicsImageRenderer(size: canvas).image { _ in
            let origin = CGPoint(
                x: (size - textSize.width) / 2,
                y: (size - textSize.height) / 2
            )
            attributed.draw(in: CGRect(origin: origin, size: textSize))
        }
    }
}
