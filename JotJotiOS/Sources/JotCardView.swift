import SwiftUI

struct JotCardView: View {
    @Bindable var jot: Jot
    var keyboardHeight: CGFloat = 0
    
    @FocusState private var isFocused: Bool
    @State private var showCopied = false
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack(spacing: 0) {
            cardHeader
            Divider()
                .opacity(0.5)
            cardEditor
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .shadow(color: .black.opacity(0.08), radius: 24, y: 12)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, keyboardHeight > 0 ? 4 : 12)
        .onAppear {
            impactFeedback.prepare()
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.background)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
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
    
    private var cardEditor: some View {
        TextEditor(text: $jot.content)
            .focused($isFocused)
            .scrollContentBackground(.hidden)
            .font(.system(size: 17, weight: .regular, design: .rounded))
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
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
