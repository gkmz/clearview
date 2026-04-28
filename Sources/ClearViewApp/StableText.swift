import AppKit
import SwiftUI

struct StableText: NSViewRepresentable {
    let text: String
    let size: CGFloat
    let weight: NSFont.Weight
    let alpha: CGFloat
    let alignment: NSTextAlignment
    let usesMonospacedDigit: Bool

    init(
        _ text: String,
        size: CGFloat,
        weight: NSFont.Weight,
        alpha: CGFloat = 1,
        alignment: NSTextAlignment = .center,
        usesMonospacedDigit: Bool = false
    ) {
        self.text = text
        self.size = size
        self.weight = weight
        self.alpha = alpha
        self.alignment = alignment
        self.usesMonospacedDigit = usesMonospacedDigit
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField(labelWithString: text)
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.lineBreakMode = .byTruncatingTail
        textField.maximumNumberOfLines = 1
        textField.alignment = alignment
        textField.wantsLayer = true
        textField.layerContentsRedrawPolicy = .onSetNeedsDisplay
        textField.layer?.isOpaque = false
        textField.layer?.backgroundColor = NSColor.clear.cgColor
        apply(to: textField)
        return textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {
        // 关键流程：透明 NSPanel 中避免 SwiftUI Text 的旧帧残影，改由 AppKit 控件稳定重绘文字。
        textField.stringValue = text
        apply(to: textField)
        textField.needsDisplay = true
        textField.layer?.setNeedsDisplay()
    }

    private func apply(to textField: NSTextField) {
        textField.font = usesMonospacedDigit
            ? NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
            : NSFont.systemFont(ofSize: size, weight: weight)
        textField.textColor = NSColor.white.withAlphaComponent(alpha)
        textField.alignment = alignment
    }
}
