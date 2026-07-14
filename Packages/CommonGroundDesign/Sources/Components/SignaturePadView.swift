#if canImport(PencilKit) && canImport(UIKit)
import SwiftUI
import PencilKit
import UIKit

public struct SignaturePadView: View {
    @Binding var signatureData: Data?
    @State private var canvasView = PKCanvasView()

    public init(signatureData: Binding<Data?>) {
        _signatureData = signatureData
    }

    public var body: some View {
        VStack(spacing: 8) {
            SignatureCanvasRepresentable(canvasView: canvasView) {
                captureSignature()
            }
            .frame(height: 160)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )

            HStack {
                Text("Sign above")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear") {
                    canvasView.drawing = PKDrawing()
                    signatureData = nil
                }
                .font(.caption.weight(.semibold))
            }
        }
    }

    private func captureSignature() {
        guard !canvasView.drawing.strokes.isEmpty else {
            signatureData = nil
            return
        }
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: 2)
        signatureData = image.pngData()
    }
}

private struct SignatureCanvasRepresentable: UIViewRepresentable {
    let canvasView: PKCanvasView
    let onDrawingChanged: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDrawingChanged: onDrawingChanged)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .label, width: 2)
        canvasView.backgroundColor = .clear
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        let onDrawingChanged: () -> Void

        init(onDrawingChanged: @escaping () -> Void) {
            self.onDrawingChanged = onDrawingChanged
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            onDrawingChanged()
        }
    }
}
#endif
