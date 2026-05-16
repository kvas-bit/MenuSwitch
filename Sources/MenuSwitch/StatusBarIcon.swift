import AppKit
import Foundation

/// Maps a provider string to an SF Symbol name appropriate for the menu bar.
/// Falls back to "switch.2" when no match is found.
func statusBarSymbolName(for provider: String?) -> String {
    guard let provider = provider?.lowercased() else {
        return "switch.2"
    }

    if provider.contains("anthropic") {
        return "text.bubble.fill"
    } else if provider.contains("deepseek") {
        return "drop.fill"
    } else if provider.contains("moonshot") || provider.contains("kimi") {
        return "moon.fill"
    } else if provider.contains("minimax") {
        return "bolt.fill"
    } else if provider.contains("custom") {
        return "gearshape.fill"
    } else {
        return "switch.2"
    }
}

/// Builds a composited NSImage for the menu bar status item.
/// The left half shows the provider symbol; the right half has a
/// small red rounded-rect "M" badge. Since `isTemplate` is set by
/// the caller, all rendering uses top-left origin (flipped: true)
/// to match NSStatusBarButton coordinate expectations.
func makeCompositeStatusBarIcon(symbolName: String, badgeText: String = "M") -> NSImage {
    let size = NSSize(width: 40, height: 18)
    let badgeSize = NSSize(width: 12, height: 12)

    return NSImage(size: size, flipped: true) { rect in
        // Symbol on the left half (y in top-left coords, so y=0 is top)
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        if let symbolImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(symbolConfig) {
            let symbolRect = NSRect(x: 1, y: 1, width: 20, height: 16)
            symbolImage.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }

        // Red badge on the right
        let badgeRect = NSRect(
            x: size.width - badgeSize.width - 2,
            y: rect.height - badgeSize.height - 2, // top-left: y = height - bh - margin
            width: badgeSize.width,
            height: badgeSize.height
        )

        let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 2, yRadius: 2)
        NSColor.systemRed.setFill()
        badgePath.fill()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 7),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle
        ]

        // Center text in badge rect
        let textRect = NSRect(
            x: badgeRect.origin.x,
            y: badgeRect.origin.y + (badgeRect.height - 7) / 2,
            width: badgeRect.width,
            height: 7
        )
        badgeText.draw(in: textRect, withAttributes: attributes)
        return true
    }
}

/// Returns a simple flat NSImage of just the SF Symbol (no badge).
func makeStatusBarIcon(symbolName: String) -> NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
    return NSImage(systemSymbolName: symbolName, accessibilityDescription: "MenuSwitch")?
        .withSymbolConfiguration(config) ?? NSImage()
}