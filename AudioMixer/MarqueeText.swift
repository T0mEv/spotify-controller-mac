import SwiftUI

private struct WidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

public struct MarqueeText: View {
    public let text: String
    public var font: Font
    public var speed: CGFloat = 40        // points/sec
    public var delay: Double = 1.2        // initial pause before scrolling
    public var height: CGFloat = 22       // row height
    public var gap: CGFloat = 24          // space between loops

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var startDate = Date()

    public init(text: String, font: Font, speed: CGFloat = 40, delay: Double = 0.8, height: CGFloat = 22, gap: CGFloat = 24) {
        self.text = text
        self.font = font
        self.speed = speed
        self.delay = delay
        self.height = height
        self.gap = gap
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Measure full untruncated width
                measuringText
                    .opacity(0)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: WidthKey.self, value: proxy.size.width)
                        }
                    )
                    .onPreferenceChange(WidthKey.self) { w in
                        textWidth = w
                        containerWidth = geo.size.width
                        resetIfNeeded()
                    }

                if shouldScroll {
                    TimelineView(.animation) { context in
                        let t = max(0, context.date.timeIntervalSince(startDate) - delay)
                        let travel = CGFloat(t) * max(1, speed)
                        let loop = textWidth + gap
                        // Offset loops from 0 -> -loop continuously
                        let x = -((travel).truncatingRemainder(dividingBy: loop))

                        HStack(spacing: gap) {
                            marqueeText
                            marqueeText
                        }
                        .offset(x: x)
                    }
                } else {
                    marqueeText
                }
            }
            .clipped()
            .onAppear {
                containerWidth = geo.size.width
                resetIfNeeded()
            }
            .onChange(of: geo.size.width) { newWidth in
                containerWidth = newWidth
                resetIfNeeded()
            }
        }
        .frame(height: height)
        .onChange(of: text) { _ in resetIfNeeded() }
        .onChange(of: speed) { _ in resetIfNeeded() }
    }

    private var marqueeText: some View {
        Text(text)
            .font(font)
            .fixedSize(horizontal: true, vertical: false)
            .lineLimit(1)
    }

    private var measuringText: some View {
        Text(text)
            .font(font)
            .fixedSize(horizontal: true, vertical: false)
            .lineLimit(1)
    }

    private var shouldScroll: Bool {
        textWidth > containerWidth + 1
    }

    private func resetIfNeeded() {
        startDate = Date()
    }
}