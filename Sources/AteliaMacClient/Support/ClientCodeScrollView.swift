import AppKit
import SwiftUI

@MainActor
struct ClientCodeScrollView<Content: View>: NSViewRepresentable {
    let contentWidth: CGFloat
    let content: Content

    init(contentWidth: CGFloat, @ViewBuilder content: () -> Content) {
        self.contentWidth = contentWidth
        self.content = content()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .overlay

        let hostingView = NSHostingView(rootView: content)
        scrollView.documentView = hostingView

        context.coordinator.hostingView = hostingView
        context.coordinator.resizeDocumentView(in: scrollView, contentWidth: contentWidth)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.hostingView?.rootView = content
        context.coordinator.resizeDocumentView(in: scrollView, contentWidth: contentWidth)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var hostingView: NSHostingView<Content>?

        @MainActor
        func resizeDocumentView(in scrollView: NSScrollView, contentWidth: CGFloat) {
            guard let hostingView else {
                return
            }

            hostingView.frame.size.width = contentWidth
            let fittingHeight = hostingView.fittingSize.height
            hostingView.setFrameSize(
                NSSize(
                    width: contentWidth,
                    height: max(fittingHeight, scrollView.contentSize.height)
                )
            )
        }
    }
}
