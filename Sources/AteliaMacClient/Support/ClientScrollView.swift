import AppKit
import SwiftUI

@MainActor
struct ClientScrollView<Content: View>: NSViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .overlay
        scrollView.contentView.postsBoundsChangedNotifications = true

        let hostingView = NSHostingView(rootView: content)
        scrollView.documentView = hostingView

        context.coordinator.hostingView = hostingView
        context.coordinator.resizeDocumentView(in: scrollView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.hostingView?.rootView = content
        context.coordinator.resizeDocumentView(in: scrollView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var hostingView: NSHostingView<Content>?

        @MainActor
        func resizeDocumentView(in scrollView: NSScrollView) {
            guard let hostingView else {
                return
            }

            let contentWidth = scrollView.contentSize.width
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
