import SwiftUI
import AppKit

struct JotEditorView: View {
    @Bindable var jot: Jot
    @FocusState private var isFocused: Bool
    @State private var showCopied = false
    
    var body: some View {
        VStack(spacing: 0) {
            editorToolbar
            Divider()
            
            AdvancedTextEditor(text: $jot.content) {
                WindowManager.shared.hide()
            }
            .focused($isFocused)
            .onChange(of: jot.content) {
                jot.updatedAt = Date()
            }
        }
        .frame(minWidth: 300)
        .onAppear { isFocused = true }
    }
    
    private var editorToolbar: some View {
        HStack(spacing: 16) {
            // 固定按钮
            Button(action: togglePin) {
                Image(systemName: jot.isPinned ? "pin.fill" : "pin")
                    .foregroundStyle(jot.isPinned ? .orange : .secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("p", modifiers: .command)
            .help("固定 ⌘P")
            
            // 复制按钮
            Button(action: copyContent) {
                Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(showCopied ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .help("复制全部 ⌘⇧C")
            
            Spacer()
            
            Text("\(jot.content.count) 字")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private func togglePin() {
        withAnimation(.spring(response: 0.3)) {
            jot.isPinned.toggle()
        }
    }
    
    private func copyContent() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(jot.content, forType: .string)
        
        withAnimation(.spring(response: 0.2)) {
            showCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showCopied = false }
        }
    }
}
