import SwiftUI
import UIKit

/// 支持 Markdown 高亮和内联图片的富文本编辑器
struct MarkdownTextEditor: UIViewRepresentable {
    @Binding var text: String
    var mediaItems: [MediaItem]
    var onInsertImage: ((Int) -> Void)?  // 在指定位置插入图片
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 17)
        textView.textContainerInset = UIEdgeInsets(top: 24, left: 20, bottom: 20, right: 20)
        textView.backgroundColor = .clear
        textView.allowsEditingTextAttributes = false
        textView.autocorrectionType = .no
        textView.smartQuotesType = .no
        
        context.coordinator.textView = textView
        context.coordinator.updateAttributedText()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            textView.becomeFirstResponder()
        }
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if context.coordinator.isEditing { return }
        context.coordinator.updateAttributedText()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkdownTextEditor
        var textView: UITextView?
        var isEditing = false
        
        // 图片缓存
        private var imageCache: [UUID: UIImage] = [:]
        
        init(_ parent: MarkdownTextEditor) {
            self.parent = parent
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing = false
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // 提取纯文本（去掉图片 attachment）
            let plainText = extractPlainText(from: textView.attributedText)
            parent.text = plainText
            
            // 重新应用高亮
            updateAttributedText()
        }
        
        // MARK: - 提取纯文本
        func extractPlainText(from attrStr: NSAttributedString) -> String {
            var result = ""
            attrStr.enumerateAttributes(in: NSRange(location: 0, length: attrStr.length)) { attrs, range, _ in
                if attrs[.attachment] == nil {
                    result += (attrStr.string as NSString).substring(with: range)
                }
            }
            return result
        }
        
        // MARK: - 更新富文本显示
        func updateAttributedText() {
            guard let textView = textView else { return }
            
            let selectedRange = textView.selectedRange
            let text = parent.text
            
            // 创建带 Markdown 高亮的富文本
            let attrStr = NSMutableAttributedString()
            
            // 解析并渲染
            let lines = text.components(separatedBy: "\n")
            for (index, line) in lines.enumerated() {
                let styledLine = styleLine(line)
                attrStr.append(styledLine)
                
                if index < lines.count - 1 {
                    attrStr.append(NSAttributedString(string: "\n"))
                }
            }
            
            // 插入内联图片
            insertInlineImages(into: attrStr)
            
            textView.attributedText = attrStr
            
            // 恢复光标
            if selectedRange.location <= attrStr.length {
                textView.selectedRange = selectedRange
            }
        }
        
        // MARK: - Markdown 行样式
        private func styleLine(_ line: String) -> NSAttributedString {
            let baseAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor.label
            ]
            
            // 标题
            if line.hasPrefix("# ") {
                return NSAttributedString(string: line, attributes: [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                    .foregroundColor: UIColor.label
                ])
            }
            if line.hasPrefix("## ") {
                return NSAttributedString(string: line, attributes: [
                    .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
                    .foregroundColor: UIColor.label
                ])
            }
            if line.hasPrefix("### ") {
                return NSAttributedString(string: line, attributes: [
                    .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                    .foregroundColor: UIColor.label
                ])
            }
            
            // 任务列表 - [ ] 或 - [x]
            if line.hasPrefix("- [ ] ") {
                return NSAttributedString(string: "☐ " + String(line.dropFirst(6)), attributes: [
                    .font: UIFont.systemFont(ofSize: 17),
                    .foregroundColor: UIColor.label
                ])
            }
            if line.hasPrefix("- [x] ") || line.hasPrefix("- [X] ") {
                return NSAttributedString(string: "☑ " + String(line.dropFirst(6)), attributes: [
                    .font: UIFont.systemFont(ofSize: 17),
                    .foregroundColor: UIColor.secondaryLabel,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue
                ])
            }
            
            // 引用块
            if line.hasPrefix("> ") {
                return NSAttributedString(string: line, attributes: [
                    .font: UIFont.italicSystemFont(ofSize: 17),
                    .foregroundColor: UIColor.secondaryLabel
                ])
            }
            
            // 普通列表
            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                return NSAttributedString(string: line, attributes: baseAttrs)
            }
            
            // 普通文本，处理内联样式
            return styleInlineMarkdown(line, baseAttrs: baseAttrs)
        }
        
        // MARK: - 内联 Markdown 样式
        private func styleInlineMarkdown(_ text: String, baseAttrs: [NSAttributedString.Key: Any]) -> NSAttributedString {
            let result = NSMutableAttributedString(string: text, attributes: baseAttrs)
            let fullRange = NSRange(location: 0, length: text.utf16.count)
            
            // 行内代码 `code`
            if let codePattern = try? NSRegularExpression(pattern: "`([^`]+)`") {
                codePattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                    if let range = match?.range {
                        result.addAttributes([
                            .font: UIFont.monospacedSystemFont(ofSize: 15, weight: .regular),
                            .foregroundColor: UIColor.systemPink,
                            .backgroundColor: UIColor.systemGray6
                        ], range: range)
                    }
                }
            }
            
            // 粗体 **text**
            if let boldPattern = try? NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*") {
                boldPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                    if let range = match?.range {
                        result.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 17), range: range)
                    }
                }
            }
            
            // 斜体 *text*
            if let italicPattern = try? NSRegularExpression(pattern: "(?<!\\*)\\*([^*]+)\\*(?!\\*)") {
                italicPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                    if let range = match?.range {
                        result.addAttribute(.font, value: UIFont.italicSystemFont(ofSize: 17), range: range)
                    }
                }
            }
            
            // 删除线 ~~text~~
            if let strikePattern = try? NSRegularExpression(pattern: "~~(.+?)~~") {
                strikePattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                    if let range = match?.range {
                        result.addAttributes([
                            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                            .foregroundColor: UIColor.secondaryLabel
                        ], range: range)
                    }
                }
            }
            
            // 链接 [text](url) 或纯 URL
            if let linkPattern = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)") {
                linkPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                    if let range = match?.range {
                        result.addAttributes([
                            .foregroundColor: UIColor.systemBlue,
                            .underlineStyle: NSUnderlineStyle.single.rawValue
                        ], range: range)
                    }
                }
            }
            
            // 纯 URL
            if let urlPattern = try? NSRegularExpression(pattern: "https?://[^\\s]+") {
                urlPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                    if let range = match?.range {
                        result.addAttributes([
                            .foregroundColor: UIColor.systemBlue,
                            .underlineStyle: NSUnderlineStyle.single.rawValue
                        ], range: range)
                    }
                }
            }
            
            return result
        }
        
        // MARK: - 插入内联图片
        private func insertInlineImages(into attrStr: NSMutableAttributedString) {
            guard let textView = textView else { return }
            let maxWidth = textView.bounds.width - 48
            
            // 查找 ![](uuid) 格式的图片标记
            let pattern = try? NSRegularExpression(pattern: "!\\[\\]\\(([a-fA-F0-9-]+)\\)")
            let text = attrStr.string
            
            // 从后往前替换，避免位置偏移
            var matches: [(NSRange, String)] = []
            pattern?.enumerateMatches(in: text, range: NSRange(location: 0, length: text.utf16.count)) { match, _, _ in
                if let range = match?.range,
                   let uuidRange = match?.range(at: 1),
                   let swiftRange = Range(uuidRange, in: text) {
                    let uuidStr = String(text[swiftRange])
                    matches.append((range, uuidStr))
                }
            }
            
            for (range, uuidStr) in matches.reversed() {
                guard let uuid = UUID(uuidString: uuidStr),
                      let mediaItem = parent.mediaItems.first(where: { $0.id == uuid }),
                      mediaItem.type == .image else { continue }
                
                // 获取或创建图片
                let image: UIImage
                if let cached = imageCache[uuid] {
                    image = cached
                } else if let uiImage = UIImage(data: mediaItem.data) {
                    let scale = min(1, maxWidth / uiImage.size.width)
                    let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
                    let renderer = UIGraphicsImageRenderer(size: newSize)
                    image = renderer.image { _ in uiImage.draw(in: CGRect(origin: .zero, size: newSize)) }
                    imageCache[uuid] = image
                } else {
                    continue
                }
                
                // 创建 attachment
                let attachment = NSTextAttachment()
                attachment.image = image
                let attachmentStr = NSAttributedString(attachment: attachment)
                
                attrStr.replaceCharacters(in: range, with: attachmentStr)
            }
        }
    }
}
