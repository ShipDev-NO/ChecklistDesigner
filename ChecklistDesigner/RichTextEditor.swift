import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var formatting: TextFormatting
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = true
        textView.allowsEditingTextAttributes = true
        textView.textAlignment = formatting.alignment.toNSTextAlignment()
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }
        textView.textAlignment = formatting.alignment.toNSTextAlignment()
        
        // Apply bold to selected text if any
        if textView.selectedRange.length > 0 {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(
                    ofSize: 16,
                    weight: formatting.isBold ? .bold : .regular
                )
            ]
            let attributedString = NSMutableAttributedString(string: textView.text)
            attributedString.addAttributes(attributes, range: textView.selectedRange)
            textView.attributedText = attributedString
            
            // Maintain selection
            let currentSelection = textView.selectedRange
            textView.selectedRange = currentSelection
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            // Update formatting based on selected text attributes
            if textView.selectedRange.length > 0 {
                let attributes = textView.attributedText.attributes(
                    at: textView.selectedRange.location,
                    effectiveRange: nil
                )
                if let font = attributes[.font] as? UIFont {
                    parent.formatting.isBold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
                }
            }
        }
    }
}

extension TextAlignment {
    func toNSTextAlignment() -> NSTextAlignment {
        switch self {
        case .left:
            return .left
        case .center:
            return .center
        case .justified:
            return .justified
        }
    }
}

struct FormattingToolbar: View {
    @Binding var formatting: TextFormatting
    let onBoldTapped: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBoldTapped) {
                Image(systemName: "bold")
                    .foregroundColor(formatting.isBold ? .blue : .primary)
            }
            Spacer()
            Menu {
                Button(action: { formatting.alignment = .left }) {
                    Label("Left", systemImage: "text.alignleft")
                }
                Button(action: { formatting.alignment = .center }) {
                    Label("Center", systemImage: "text.aligncenter")
                }
                Button(action: { formatting.alignment = .justified }) {
                    Label("Justified", systemImage: "text.justify")
                }
            } label: {
                Image(systemName: formatting.alignment == .left ? "text.alignleft" :
                                formatting.alignment == .center ? "text.aligncenter" : "text.justify")
            }
        }
        .padding(.horizontal)
    }
}