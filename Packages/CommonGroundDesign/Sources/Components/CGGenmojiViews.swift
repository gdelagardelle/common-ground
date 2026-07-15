import SwiftUI
import UIKit
import CommonGroundCore

// MARK: - Genmoji picker (system keyboard)

public struct CGGenmojiPicker: UIViewRepresentable {
    @Binding var imageContent: Data?
    var onGlyphChanged: ((Data?) -> Void)?

    public init(imageContent: Binding<Data?>, onGlyphChanged: ((Data?) -> Void)? = nil) {
        self._imageContent = imageContent
        self.onGlyphChanged = onGlyphChanged
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.supportsAdaptiveImageGlyph = true
        textView.allowsEditingTextAttributes = true
        textView.font = .systemFont(ofSize: 72)
        textView.textAlignment = .center
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.textContainer.maximumNumberOfLines = 1
        textView.textContainer.lineFragmentPadding = 0
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.returnKeyType = .done
        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        if imageContent == nil, !uiView.text.isEmpty {
            uiView.attributedText = NSAttributedString()
        }
    }

    public final class Coordinator: NSObject, UITextViewDelegate {
        var parent: CGGenmojiPicker

        init(parent: CGGenmojiPicker) {
            self.parent = parent
        }

        public func textViewDidChange(_ textView: UITextView) {
            let content = GenmojiSupport.extractImageContent(from: textView.attributedText)
            parent.imageContent = content
            parent.onGlyphChanged?(content)
        }
    }
}

// MARK: - Rendered genmoji image

public struct CGGenmojiImage: View {
    let data: Data
    let size: CGFloat

    @State private var rendered: UIImage?

    public init(data: Data, size: CGFloat) {
        self.data = data
        self.size = size
    }

    public var body: some View {
        Group {
            if let rendered {
                Image(uiImage: rendered)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .frame(width: size, height: size)
        .task(id: data) {
            rendered = GenmojiSupport.renderImage(from: data, size: size)
        }
    }
}

// MARK: - Picker sheet

public struct CGGenmojiPickerSheet: View {
    @Binding var imageContent: Data?
    @Environment(\.dismiss) private var dismiss

    @State private var draftContent: Data?
    @State private var hasGlyph = false

    public init(imageContent: Binding<Data?>) {
        self._imageContent = imageContent
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: CGSpacing.lg) {
                VStack(spacing: CGSpacing.sm) {
                    Text(L10n.avatarGenmojiSheetTitle)
                        .font(CGTypography.section)

                    Text(L10n.avatarGenmojiSheetHint)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, CGSpacing.md)

                ZStack {
                    RoundedRectangle(cornerRadius: CGRadius.xl, style: .continuous)
                        .fill(CGGradient.aurora.opacity(0.25))
                        .frame(height: 160)

                    if let draftContent {
                        CGGenmojiImage(data: draftContent, size: 120)
                    } else {
                        CGGenmojiPicker(imageContent: $draftContent) { content in
                            hasGlyph = content != nil
                        }
                        .frame(height: 120)
                        .padding(.horizontal, CGSpacing.lg)
                    }
                }
                .padding(.horizontal, CGSpacing.md)

                if hasGlyph {
                    Button(L10n.avatarGenmojiClear) {
                        draftContent = nil
                        hasGlyph = false
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.top, CGSpacing.lg)
            .background(CGColor.canvas)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonSave) {
                        imageContent = draftContent
                        dismiss()
                    }
                    .disabled(draftContent == nil)
                }
            }
            .onAppear {
                draftContent = imageContent
                hasGlyph = imageContent != nil
            }
        }
    }
}
