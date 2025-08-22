import SwiftUI

struct ScrubbableProgressBar: View {
    var progressMs: Int
    var durationMs: Int
    var trackColor: Color = Color.black.opacity(0.35)
    var fillColor: Color = .white
    var height: CGFloat = 6
    var onScrub: (Int) -> Void = { _ in }
    var onScrubEnd: (Int) -> Void = { _ in }

    @State private var isDragging = false
    @State private var dragMs: Int = 0

    var body: some View {
        GeometryReader { geo in
            let totalW = max(1, geo.size.width)
            let clampedProg = max(0, min(progressMs, durationMs))
            let showMs = isDragging ? dragMs : clampedProg
            let frac = durationMs > 0 ? CGFloat(showMs) / CGFloat(durationMs) : 0

            ZStack(alignment: .leading) {
                Capsule().fill(trackColor)
                Capsule()
                    .fill(fillColor)
                    .frame(width: totalW * frac)
            }
            .contentShape(Rectangle()) // easier to hit
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let x = min(max(0, value.location.x), totalW)
                        let ms = durationMs > 0 ? Int((x / totalW) * CGFloat(durationMs)) : 0
                        isDragging = true
                        dragMs = ms
                        onScrub(ms)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onScrubEnd(dragMs)
                    }
            )
        }
        .frame(height: height)
    }
}