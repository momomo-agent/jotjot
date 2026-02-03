import SwiftUI
import AppKit

struct AdvancedTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onEscape: (() -> Void)?
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! VSCodeTextView
        
        textView.delegate = context.coordinator
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = .labelColor
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.onEscape = onEscape
        
        // 行间距
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 6
        textView.defaultParagraphStyle = style
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! VSCodeTextView
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
        textView.onEscape = onEscape
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: AdvancedTextEditor
        
        init(_ parent: AdvancedTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

// MARK: - VSCode Style TextView
class VSCodeTextView: NSTextView {
    var onEscape: (() -> Void)?
    
    // 存储多光标选择的搜索词
    private var lastSelectedWord: String?
    
    override class var defaultMenu: NSMenu? {
        return nil
    }
    
    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode
        
        // Esc - 收起窗口
        if keyCode == 53 { // Escape
            onEscape?()
            return
        }
        
        // ⌘D - 选中下一个相同词
        if flags == .command && keyCode == 2 { // D
            selectNextOccurrence()
            return
        }
        
        // ⌥↑ - 向上移动行
        if flags == .option && keyCode == 126 { // Up
            moveLineUp()
            return
        }
        
        // ⌥↓ - 向下移动行
        if flags == .option && keyCode == 125 { // Down
            moveLineDown()
            return
        }
        
        // ⌘⇧K - 删除整行
        if flags == [.command, .shift] && keyCode == 40 { // K
            deleteLine()
            return
        }
        
        // ⌘Enter - 在下方插入新行
        if flags == .command && keyCode == 36 { // Enter
            insertLineBelow()
            return
        }
        
        // ⌘⇧Enter - 在上方插入新行
        if flags == [.command, .shift] && keyCode == 36 { // Enter
            insertLineAbove()
            return
        }
        
        // ⌘L - 选中当前行
        if flags == .command && keyCode == 37 { // L
            selectCurrentLine()
            return
        }
        
        // ⌘⇧D - 复制当前行
        if flags == [.command, .shift] && keyCode == 2 { // D
            duplicateLine()
            return
        }
        
        // ⌘/ - 切换注释（对于代码笔记）
        if flags == .command && keyCode == 44 { // /
            toggleComment()
            return
        }
        
        super.keyDown(with: event)
    }
    
    // MARK: - VSCode Actions
    
    /// ⌘D - 选中下一个相同词
    private func selectNextOccurrence() {
        guard let textStorage = self.textStorage else { return }
        let fullText = textStorage.string as NSString
        
        // 获取当前选中的文本
        guard let selectedRange = selectedRanges.first?.rangeValue,
              selectedRange.length > 0 else {
            // 没有选中内容，先选中当前词
            selectWord(nil)
            if let range = selectedRanges.first?.rangeValue, range.length > 0 {
                lastSelectedWord = (string as NSString).substring(with: range)
            }
            return
        }
        
        let selectedText = fullText.substring(with: selectedRange)
        lastSelectedWord = selectedText
        
        // 从当前选择之后开始搜索
        let searchStart = NSMaxRange(selectedRange)
        let searchRange = NSRange(location: searchStart, length: fullText.length - searchStart)
        
        var nextRange = fullText.range(of: selectedText, options: [], range: searchRange)
        
        // 如果后面没找到，从头开始找
        if nextRange.location == NSNotFound {
            let wrapRange = NSRange(location: 0, length: selectedRange.location)
            nextRange = fullText.range(of: selectedText, options: [], range: wrapRange)
        }
        
        if nextRange.location != NSNotFound {
            // 添加新的选择（多光标）
            var newRanges = selectedRanges.map { $0.rangeValue }
            if !newRanges.contains(nextRange) {
                newRanges.append(nextRange)
            }
            setSelectedRanges(newRanges.map { NSValue(range: $0) }, affinity: .downstream, stillSelecting: false)
            scrollRangeToVisible(nextRange)
        }
    }
    
    /// ⌥↑ - 向上移动行
    private func moveLineUp() {
        guard let textStorage = self.textStorage else { return }
        let fullText = textStorage.string as NSString
        
        let selectedRange = self.selectedRange()
        let lineRange = fullText.lineRange(for: selectedRange)
        
        // 如果已经是第一行，不能再上移
        if lineRange.location == 0 { return }
        
        // 获取上一行的范围
        let prevLineEnd = lineRange.location - 1
        let prevLineRange = fullText.lineRange(for: NSRange(location: prevLineEnd, length: 0))
        
        // 获取当前行和上一行的内容
        let currentLine = fullText.substring(with: lineRange)
        let prevLine = fullText.substring(with: prevLineRange)
        
        // 交换两行
        let combinedRange = NSRange(location: prevLineRange.location, length: lineRange.location + lineRange.length - prevLineRange.location)
        
        undoManager?.beginUndoGrouping()
        
        if let storage = textStorage as? NSTextStorage {
            storage.replaceCharacters(in: combinedRange, with: currentLine + prevLine)
        }
        
        undoManager?.endUndoGrouping()
        
        // 更新选择位置
        let newLocation = prevLineRange.location + (selectedRange.location - lineRange.location)
        setSelectedRange(NSRange(location: newLocation, length: selectedRange.length))
    }
    
    /// ⌥↓ - 向下移动行
    private func moveLineDown() {
        guard let textStorage = self.textStorage else { return }
        let fullText = textStorage.string as NSString
        
        let selectedRange = self.selectedRange()
        let lineRange = fullText.lineRange(for: selectedRange)
        
        // 如果已经是最后一行，不能再下移
        let lineEnd = NSMaxRange(lineRange)
        if lineEnd >= fullText.length { return }
        
        // 获取下一行的范围
        let nextLineRange = fullText.lineRange(for: NSRange(location: lineEnd, length: 0))
        
        // 获取当前行和下一行的内容
        let currentLine = fullText.substring(with: lineRange)
        var nextLine = fullText.substring(with: nextLineRange)
        
        // 确保下一行有换行符
        if !nextLine.hasSuffix("\n") && !currentLine.hasSuffix("\n") {
            nextLine += "\n"
        }
        
        // 交换两行
        let combinedRange = NSRange(location: lineRange.location, length: nextLineRange.location + nextLineRange.length - lineRange.location)
        
        undoManager?.beginUndoGrouping()
        
        if let storage = textStorage as? NSTextStorage {
            storage.replaceCharacters(in: combinedRange, with: nextLine + currentLine.trimmingCharacters(in: .newlines) + (currentLine.hasSuffix("\n") ? "\n" : ""))
        }
        
        undoManager?.endUndoGrouping()
        
        // 更新选择位置
        let newLocation = lineRange.location + nextLineRange.length + (selectedRange.location - lineRange.location)
        setSelectedRange(NSRange(location: min(newLocation, fullText.length), length: selectedRange.length))
    }
    
    /// ⌘⇧K - 删除整行
    private func deleteLine() {
        guard let textStorage = self.textStorage else { return }
        let fullText = textStorage.string as NSString
        
        let selectedRange = self.selectedRange()
        let lineRange = fullText.lineRange(for: selectedRange)
        
        undoManager?.beginUndoGrouping()
        
        if let storage = textStorage as? NSTextStorage {
            storage.replaceCharacters(in: lineRange, with: "")
        }
        
        undoManager?.endUndoGrouping()
        
        setSelectedRange(NSRange(location: min(lineRange.location, self.string.count), length: 0))
    }
    
    /// ⌘Enter - 在下方插入新行
    private func insertLineBelow() {
        guard let textStorage = self.textStorage else { return }
        let fullText = textStorage.string as NSString
        
        let selectedRange = self.selectedRange()
        let lineRange = fullText.lineRange(for: selectedRange)
        let lineEnd = NSMaxRange(lineRange)
        
        undoManager?.beginUndoGrouping()
        
        let insertPos = lineEnd > 0 && fullText.character(at: lineEnd - 1) == 10 ? lineEnd : lineEnd
        
        if let storage = textStorage as? NSTextStorage {
            let newline = lineEnd > 0 && fullText.character(at: lineEnd - 1) == 10 ? "" : "\n"
            storage.replaceCharacters(in: NSRange(location: insertPos, length: 0), with: newline + "\n")
        }
        
        undoManager?.endUndoGrouping()
        
        setSelectedRange(NSRange(location: insertPos + 1, length: 0))
    }
    
    /// ⌘⇧Enter - 在上方插入新行
    private func insertLineAbove() {
        guard let textStorage = self.textStorage else { return }
        let fullText = textStorage.string as NSString
        
        let selectedRange = self.selectedRange()
        let lineRange = fullText.lineRange(for: selectedRange)
        
        undoManager?.beginUndoGrouping()
        
        if let storage = textStorage as? NSTextStorage {
            storage.replaceCharacters(in: NSRange(location: lineRange.location, length: 0), with: "\n")
        }
        
        undoManager?.endUndoGrouping()
        
        setSelectedRange(NSRange(location: lineRange.location, length: 0))
    }
    
    /// ⌘L - 选中当前行
    private func selectCurrentLine() {
        let fullText = string as NSString
        let selectedRange = self.selectedRange()
        let lineRange = fullText.lineRange(for: selectedRange)
        setSelectedRange(lineRange)
    }
    
    /// ⌘⇧D - 复制当前行
    private func duplicateLine() {
        guard let textStorage = self.textStorage else { return }
        let fullText = textStorage.string as NSString
        
        let selectedRange = self.selectedRange()
        let lineRange = fullText.lineRange(for: selectedRange)
        var lineContent = fullText.substring(with: lineRange)
        
        // 确保有换行符
        if !lineContent.hasSuffix("\n") {
            lineContent += "\n"
        }
        
        undoManager?.beginUndoGrouping()
        
        if let storage = textStorage as? NSTextStorage {
            storage.replaceCharacters(in: NSRange(location: NSMaxRange(lineRange), length: 0), with: lineContent)
        }
        
        undoManager?.endUndoGrouping()
        
        // 移动光标到新行
        let newLocation = NSMaxRange(lineRange) + (selectedRange.location - lineRange.location)
        setSelectedRange(NSRange(location: newLocation, length: selectedRange.length))
    }
    
    /// ⌘/ - 切换注释
    private func toggleComment() {
        guard let textStorage = self.textStorage else { return }
        let fullText = textStorage.string as NSString
        
        let selectedRange = self.selectedRange()
        let lineRange = fullText.lineRange(for: selectedRange)
        let lineContent = fullText.substring(with: lineRange)
        
        undoManager?.beginUndoGrouping()
        
        let trimmed = lineContent.trimmingCharacters(in: .whitespaces)
        
        if let storage = textStorage as? NSTextStorage {
            if trimmed.hasPrefix("// ") {
                // 移除注释
                if let range = lineContent.range(of: "// ") {
                    let nsRange = NSRange(range, in: lineContent)
                    let removeRange = NSRange(location: lineRange.location + nsRange.location, length: nsRange.length)
                    storage.replaceCharacters(in: removeRange, with: "")
                }
            } else if trimmed.hasPrefix("//") {
                // 移除注释（无空格）
                if let range = lineContent.range(of: "//") {
                    let nsRange = NSRange(range, in: lineContent)
                    let removeRange = NSRange(location: lineRange.location + nsRange.location, length: nsRange.length)
                    storage.replaceCharacters(in: removeRange, with: "")
                }
            } else {
                // 添加注释
                storage.replaceCharacters(in: NSRange(location: lineRange.location, length: 0), with: "// ")
            }
        }
        
        undoManager?.endUndoGrouping()
    }
}

// MARK: - Custom ScrollView for VSCodeTextView
extension NSTextView {
    static func scrollableTextView() -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        
        let textView = VSCodeTextView()
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        scrollView.documentView = textView
        
        return scrollView
    }
}
