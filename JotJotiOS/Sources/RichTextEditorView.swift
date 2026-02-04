import SwiftUI
import UIKit

struct RichTextEditorView: UIViewRepresentable {
    @Bindable var jot: Jot
    @Binding var textViewRef: UITextView?
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 17)
        textView.textContainerInset = UIEdgeInsets(top: 24, left: 20, bottom: 20, right: 20)
        textView.backgroundColor = .clear
        textView.allowsEditingTextAttributes = true
        textView.typingAttributes = RichTextHelper.defaultAttributes
        textView.attributedText = jot.attributedContent
        
        DispatchQueue.main.async {
            self.textViewRef = textView
            textView.becomeFirstResponder()
        }
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if context.coordinator.currentJotId != jot.id {
            context.coordinator.currentJotId = jot.id
            textView.attributedText = jot.attributedContent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditorView
        var currentJotId: UUID?
        
        init(_ parent: RichTextEditorView) {
            self.parent = parent
            self.currentJotId = parent.jot.id
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.jot.setAttributedContent(textView.attributedText)
        }
    }
}
