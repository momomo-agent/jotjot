import SwiftUI

struct JotCardView: View {
    @Bindable var jot: Jot
    var keyboardHeight: CGFloat = 0
    var onDelete: (() -> Void)? = nil
    
    @FocusState private var isFocused: Bool
    @State private var showCopied = false
    @State private var showDeleteConfirm = false
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部时间戳
            HStack {
                Text(jot.updatedAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                if jot.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            cardEditor
            
            Divider()
                .opacity(0.3)
            cardFooter
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 2)
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        .shadow(color: .black.opacity(0.1), radius: 32, y: 16)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, keyboardHeight > 0 ? 8 : 16)
        .onAppear {
            impactFeedback.prepare()
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(.background)
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.primary.opacity(0.04), lineWidth: 0.5)
            )
    }
    
    private var cardFooter: some View {
        HStack {
            pinButton
            Spacer()
            micButton
            Spacer()
            deleteButton
            Spacer()
            copyButton
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 14)
    }
    
    private var cardHeader: some View {
        HStack(spacing: 16) {
            pinButton
            Spacer()
            timestampLabel
            micButton
            copyButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    private var micButton: some View {
        Button(action: toggleVoiceInput) {
            Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(speechRecognizer.isRecording ? .red : .secondary)
                .symbolEffect(.pulse.byLayer, options: .repeating, isActive: speechRecognizer.isRecording)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var timestampLabel: some View {
        Text(jot.updatedAt, style: .relative)
            .font(.caption)
            .foregroundStyle(.tertiary)
    }
    
    private var pinButton: some View {
        Button(action: togglePin) {
            Image(systemName: jot.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(jot.isPinned ? .orange : .secondary)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var copyButton: some View {
        Button(action: copyContent) {
            Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(showCopied ? .green : .secondary)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var deleteButton: some View {
        Button(action: { showDeleteConfirm = true }) {
            Image(systemName: "trash")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(ScaleButtonStyle())
        .confirmationDialog("删除这条笔记？", isPresented: $showDeleteConfirm) {
            Button("删除", role: .destructive) {
                impactFeedback.impactOccurred(intensity: 0.6)
                onDelete?()
            }
            Button("取消", role: .cancel) {}
        }
    }
    
    private var cardEditor: some View {
        TextEditor(text: $jot.content)
            .focused($isFocused)
            .scrollContentBackground(.hidden)
            .font(.system(size: 18, weight: .regular, design: .default))
            .lineSpacing(4)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            .onChange(of: jot.content) {
                jot.updatedAt = Date()
            }
            .onAppear { 
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
    }
    
    private func togglePin() {
        impactFeedback.impactOccurred(intensity: 0.5)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            jot.isPinned.toggle()
        }
    }
    
    private func copyContent() {
        UIPasteboard.general.string = jot.content
        impactFeedback.impactOccurred(intensity: 0.4)
        
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            showCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.2)) { 
                showCopied = false 
            }
        }
    }
    
    private func toggleVoiceInput() {
        impactFeedback.impactOccurred(intensity: 0.5)
        
        // 设置转写完成回调
        speechRecognizer.onTranscriptionComplete = { text in
            // 追加到笔记内容
            if jot.content.isEmpty {
                jot.content = text
            } else {
                jot.content += "\n" + text
            }
            jot.updatedAt = Date()
        }
        
        speechRecognizer.toggleRecording()
    }
}

// MARK: - 按钮缩放效果
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
