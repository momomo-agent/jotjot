import SwiftUI
import AppKit

/// Mac 版 Markdown 高亮编辑器
struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onEscape: (() -> Void)?
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 14)
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 16, height: 16)
        
        context.coordinator.textView = textView
        context.coordinator.applyMarkdownHighlighting()
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if context.coordinator.isEditing { return }
        
        if textView.string != text {
            context.coordinator.applyMarkdownHighlighting()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextEditor
        var textView: NSTextView?
        var isEditing = false
        
        init(_ parent: MarkdownTextEditor) {
            self.parent = parent
        }
        
        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
        }
        
        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            applyMarkdownHighlighting()
        }
        
        func applyMarkdownHighlighting() {
            guard let textView = textView else { return }
            let text = parent.text
            let selectedRanges = textView.selectedRanges
            
            let attrStr = NSMutableAttributedString()
            let lines = text.components(separatedBy: "\n")
            
            for (i, line) in lines.enumerated() {
                attrStr.append(styleLine(line))
                if i < lines.count - 1 {
                    attrStr.append(NSAttributedString(string: "\n"))
                }
            }
            
            textView.textStorage?.setAttributedString(attrStr)
            textView.selectedRanges = selectedRanges
        }
        
        private func styleLine(_ line: String) -> NSAttributedString {
            let baseFont = NSFont.systemFont(ofSize: 14)
            let baseAttrs: [NSAttributedString.Key: Any] = [
                .font: baseFont,
                .foregroundColor: NSColor.labelColor
            ]
            
            // 标题
            if line.hasPrefix("# ") {
                return NSAttributedString(string: line, attributes: [
                    .font: NSFont.systemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: NSColor.labelColor
                ])
            }
            if line.hasPrefix("## ") {
                return NSAttributedString(string: line, attributes: [
                    .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
                    .foregroundColor: NSColor.labelColor
                ])
            }
            if line.hasPrefix("### ") {
                return NSAttributedString(string: line, attributes: [
                    .font: NSFont.systemFont(ofSize: 16, weight: .medium),
                    .foregroundColor: NSColor.labelColor
                ])
            }
            
            // 任务列表
            if line.hasPrefix("- [ ] ") {
                return NSAttributedString(string: "☐ " + String(line.dropFirst(6)), attributes: baseAttrs)
            }
            if line.hasPrefix("- [x] ") || line.hasPrefix("- [X] ") {
                return NSAttributedString(string: "☑ " + String(line.dropFirst(6)), attributes: [
                    .font: baseFont,
                    .foregroundColor: NSColor.secondaryLabelColor,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue
                ])
            }
            
            // 引用
            if line.hasPrefix("> ") {
                return NSAttributedString(string: line, attributes: [
                    .font: NSFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(.italic), size: 14) ?? baseFont,
                    .foregroundColor: NSColor.secondaryLabelColor
                ])
            }
            
            return styleInline(line, baseAttrs: baseAttrs)
        }
        
        private func styleInline(_ text: String, baseAttrs: [NSAttributedString.Key: Any]) -> NSAttributedString {
            let result = NSMutableAttributedString(string: text, attributes: baseAttrs)
            let range = NSRange(location: 0, length: text.utf16.count)
            
            // 代码
            if let pattern = try? NSRegularExpression(pattern: "`([^`]+)`") {
                pattern.enumerateMatches(in: text, range: range) { match, _, _ in
                    if let r = match?.range {
                        result.addAttributes([
                            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                            .foregroundColor: NSColor.systemPink,
                            .backgroundColor: NSColor.quaternaryLabelColor
                        ], range: r)
                    }
                }
            }
            
            // 粗体
            if let pattern = try? NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*") {
                pattern.enumerateMatches(in: text, range: range) { match, _, _ in
                    if let r = match?.range {
                        result.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 14), range: r)
                    }
                }
            }
            
            return result
        }
    }
}
