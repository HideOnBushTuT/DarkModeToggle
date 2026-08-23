import SwiftUI

enum TogglePalette {
    static let daySky = Color(red: 162 / 255, green: 209 / 255, blue: 253 / 255)
    static let nightSky = Color(red: 31 / 255, green: 37 / 255, blue: 51 / 255)
    static let sun = Color(red: 255 / 255, green: 193 / 255, blue: 135 / 255)
    static let moon = Color(red: 222 / 255, green: 229 / 255, blue: 243 / 255)
    static let star = moon
}

public struct DarkModeToggle: View {
    @Binding private var isDarkMode: Bool
    let initializerStyle: Style
    @Environment(\.darkModeToggleStyle) private var environmentStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var committedProgress: CGFloat
    @State private var dragProgress: CGFloat?
    @State private var dragStartProgress: CGFloat?
    @State private var dragOriginTranslationX: CGFloat?
    @State private var dragAxis: DarkModeToggleDragAxis?
    @State private var suppressActivation = false

    public init(isDarkMode: Binding<Bool>) {
        self.init(isDarkMode: isDarkMode, initializerStyle: .original)
    }

    @available(
        *,
        deprecated,
        message: "Use init(isDarkMode:) followed by .darkModeStyle(.vivid)."
    )
    public init(vividIsDarkMode: Binding<Bool>) {
        self.init(isDarkMode: vividIsDarkMode, initializerStyle: .vivid)
    }

    private init(
        isDarkMode: Binding<Bool>,
        initializerStyle: Style
    ) {
        _isDarkMode = isDarkMode
        self.initializerStyle = initializerStyle
        _committedProgress = State(
            initialValue: DarkModeToggleInteraction.restingProgress(
                isDarkMode: isDarkMode.wrappedValue
            )
        )
    }

    public var body: some View {
        Button {
            guard !suppressActivation else {
                suppressActivation = false
                return
            }

            settle(to: !isDarkMode, source: .activation)
        } label: {
            GeometryReader { proxy in
                let metrics = DarkModeToggleMetrics(width: proxy.size.width)
                let visualStyle = DarkModeToggleStyleResolver.resolve(
                    environmentStyle: environmentStyle,
                    initializerStyle: initializerStyle,
                    supportsLiquidGlass: supportsLiquidGlass
                )

                DarkModeToggleVisuals(
                    appearanceProgress: appearanceProgress,
                    positionProgress: positionProgress,
                    visualStyle: visualStyle,
                    metrics: metrics,
                    reduceMotion: reduceMotion,
                    onDragChanged: { value, presentedProgress in
                        dragChanged(
                            value,
                            presentedProgress: presentedProgress,
                            travel: metrics.translationTravel
                        )
                    },
                    onDragEnded: { value in
                        dragEnded(value, travel: metrics.translationTravel)
                    }
                )
            }
        }
        .buttonStyle(.plain)
        .aspectRatio(
            DarkModeToggleMetrics.referenceComponentSize.width
                / DarkModeToggleMetrics.referenceComponentSize.height,
            contentMode: .fit
        )
        .accessibilityLabel("Dark Mode")
        .accessibilityValue(isDarkMode ? "On" : "Off")
        .accessibilityHint("Double tap to change appearance")
        .accessibilityIdentifier("darkModeToggle")
        .accessibilityAddTraits(isDarkMode ? .isSelected : [])
        .onChange(of: isDarkMode) { _, newValue in
            synchronizeCommittedProgress(isDarkMode: newValue)
        }
    }

    private var endpointProgress: CGFloat {
        DarkModeToggleInteraction.restingProgress(isDarkMode: isDarkMode)
    }

    private var supportsLiquidGlass: Bool {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            return true
        }
        #endif
        return false
    }

    private var appearanceProgress: CGFloat {
        dragProgress ?? committedProgress
    }

    private var positionProgress: CGFloat {
        if let dragProgress {
            return dragProgress
        }

        return reduceMotion ? endpointProgress : committedProgress
    }

    private func dragChanged(
        _ value: DragGesture.Value,
        presentedProgress: CGFloat,
        travel: CGFloat
    ) {
        if dragAxis == nil {
            suppressActivation = true
            dragAxis = DarkModeToggleInteraction.axis(for: value.translation)
            dragStartProgress = presentedProgress
            dragOriginTranslationX = value.translation.width
        }

        guard dragAxis == .horizontal,
              let dragStartProgress,
              let dragOriginTranslationX else {
            return
        }

        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            dragProgress = DarkModeToggleInteraction.progress(
                startingAt: dragStartProgress,
                translation: value.translation.width - dragOriginTranslationX,
                travel: travel
            )
        }
    }

    private func dragEnded(_ value: DragGesture.Value, travel: CGFloat) {
        defer { clearSuppressionAfterGesture() }

        guard dragAxis == .horizontal,
              let dragStartProgress,
              let dragOriginTranslationX else {
            resetGesture()
            return
        }

        let targetIsDark = DarkModeToggleInteraction.targetIsDark(
            startingAt: dragStartProgress,
            predictedTranslation: value.predictedEndTranslation.width
                - dragOriginTranslationX,
            travel: travel
        )
        settle(to: targetIsDark, source: .drag)
    }

    private func settle(to targetIsDark: Bool, source: CommitSource) {
        let targetProgress = DarkModeToggleInteraction.restingProgress(
            isDarkMode: targetIsDark
        )

        if reduceMotion, source == .activation {
            if isDarkMode != targetIsDark {
                isDarkMode = targetIsDark
            }
            dragProgress = nil
            resetGestureMetadata()

            withAnimation(.easeOut(duration: 0.2)) {
                committedProgress = targetProgress
            }
            return
        }

        let animation: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(response: 0.35, dampingFraction: 0.82)

        withAnimation(animation) {
            if isDarkMode != targetIsDark {
                isDarkMode = targetIsDark
            }
            committedProgress = targetProgress
            dragProgress = nil
        }
        resetGestureMetadata()
    }

    private func synchronizeCommittedProgress(isDarkMode: Bool) {
        guard dragAxis == nil, dragProgress == nil else { return }

        let targetProgress = DarkModeToggleInteraction.restingProgress(
            isDarkMode: isDarkMode
        )
        guard committedProgress != targetProgress else { return }

        let animation: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(response: 0.35, dampingFraction: 0.82)
        withAnimation(animation) {
            committedProgress = targetProgress
        }
    }

    private func resetGesture() {
        dragProgress = nil
        resetGestureMetadata()
    }

    private func resetGestureMetadata() {
        dragStartProgress = nil
        dragOriginTranslationX = nil
        dragAxis = nil
    }

    private func clearSuppressionAfterGesture() {
        Task { @MainActor in
            suppressActivation = false
        }
    }

    private enum CommitSource {
        case activation
        case drag
    }
}

enum DarkModeToggleVisualStyle: Equatable, Sendable {
    case original
    case vivid
    case liquidGlass
}

private struct DarkModeToggleVisuals: View, @MainActor Animatable {
    var appearanceProgress: CGFloat
    var positionProgress: CGFloat
    let visualStyle: DarkModeToggleVisualStyle
    let metrics: DarkModeToggleMetrics
    let reduceMotion: Bool
    let onDragChanged: (DragGesture.Value, CGFloat) -> Void
    let onDragEnded: (DragGesture.Value) -> Void

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(appearanceProgress, positionProgress) }
        set {
            appearanceProgress = newValue.first
            positionProgress = newValue.second
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            track
            .offset(y: (metrics.componentHeight - metrics.trackHeight) / 2)

            CelestialThumb(
                appearanceProgress: appearanceProgress,
                positionProgress: positionProgress,
                metrics: metrics,
                visualStyle: visualStyle
            )
        }
        .frame(
            width: metrics.width,
            height: metrics.componentHeight,
            alignment: .topLeading
        )
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(
                minimumDistance: DarkModeToggleInteraction.dragThreshold,
                coordinateSpace: .local
            )
            .onChanged { value in
                onDragChanged(value, positionProgress)
            }
            .onEnded(onDragEnded)
        )
    }

    @ViewBuilder
    private var track: some View {
        switch visualStyle {
        case .original, .liquidGlass:
            ToggleTrack(
                progress: appearanceProgress,
                metrics: metrics,
                reduceMotion: reduceMotion
            )
        case .vivid:
            VividToggleTrack(
                progress: appearanceProgress,
                metrics: metrics,
                reduceMotion: reduceMotion
            )
        }
    }
}

private struct ToggleTrack: View {
    let progress: CGFloat
    let metrics: DarkModeToggleMetrics
    let reduceMotion: Bool

    var body: some View {
        let scale = metrics.trackScale
        let clampedProgress = min(max(progress, 0), 1)

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 33.15 * scale, style: .continuous)
                .fill(TogglePalette.daySky)
                .frame(width: 170.3 * scale, height: 66.3 * scale)
                .offset(x: 1.35 * scale, y: 1.35 * scale)

            RoundedRectangle(cornerRadius: 33.15 * scale, style: .continuous)
                .fill(TogglePalette.nightSky)
                .opacity(clampedProgress)
                .frame(width: 170.3 * scale, height: 66.3 * scale)
                .offset(x: 1.35 * scale, y: 1.35 * scale)

            RoundedRectangle(cornerRadius: 33.15 * scale, style: .continuous)
                .stroke(dayBorderGradient, lineWidth: 1.3 * scale)
                .opacity(1 - clampedProgress)
                .frame(width: 170.3 * scale, height: 66.3 * scale)
                .offset(x: 1.35 * scale, y: 1.35 * scale)

            RoundedRectangle(cornerRadius: 33.15 * scale, style: .continuous)
                .stroke(nightBorderGradient, lineWidth: 1.3 * scale)
                .opacity(clampedProgress)
                .frame(width: 170.3 * scale, height: 66.3 * scale)
                .offset(x: 1.35 * scale, y: 1.35 * scale)

            ZStack(alignment: .topLeading) {
                DayScene(reduceMotion: reduceMotion)
                    .opacity(1 - clampedProgress)

                NightScene(reduceMotion: reduceMotion)
                    .opacity(clampedProgress)
            }
            .mask(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 32.5 * scale, style: .continuous)
                    .frame(width: 169 * scale, height: 65 * scale)
                    .offset(x: 2 * scale, y: 2 * scale)
            }

            RoundedRectangle(cornerRadius: 32.5 * scale, style: .continuous)
                .strokeBorder(dayInnerEdgeGradient, lineWidth: 3.2 * scale)
                .opacity(1 - clampedProgress)
                .frame(width: 169 * scale, height: 65 * scale)
                .offset(x: 2 * scale, y: 2 * scale)
                .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: 32.5 * scale, style: .continuous)
                .strokeBorder(nightInnerEdgeGradient, lineWidth: 3.2 * scale)
                .opacity(clampedProgress)
                .frame(width: 169 * scale, height: 65 * scale)
                .offset(x: 2 * scale, y: 2 * scale)
                .allowsHitTesting(false)
        }
        .frame(width: metrics.width, height: metrics.trackHeight, alignment: .topLeading)
        .drawingGroup()
    }

    private var dayBorderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 108 / 255, green: 184 / 255, blue: 1),
                Color.white.opacity(0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var nightBorderGradient: LinearGradient {
        LinearGradient(
            colors: [Color.black.opacity(0.65), Color.white.opacity(0.04)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var dayInnerEdgeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.2),
                Color.clear,
                Color(red: 114 / 255, green: 187 / 255, blue: 1).opacity(0.58),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var nightInnerEdgeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.black.opacity(0.58),
                Color.clear,
                Color.white.opacity(0.04),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview("Light") {
    @Previewable @State var isDarkMode = false

    DarkModeToggle(isDarkMode: $isDarkMode)
        .frame(width: 260)
        .padding()
}

#Preview("Dark") {
    @Previewable @State var isDarkMode = true

    DarkModeToggle(isDarkMode: $isDarkMode)
        .frame(width: 260)
        .padding()
        .background(Color(red: 83 / 255, green: 92 / 255, blue: 114 / 255))
}

#Preview("Vivid Light") {
    @Previewable @State var isDarkMode = false

    DarkModeToggle(isDarkMode: $isDarkMode)
        .darkModeStyle(.vivid)
        .frame(width: 260)
        .padding()
        .background(Color(red: 235 / 255, green: 246 / 255, blue: 1))
}

#Preview("Vivid Dark") {
    @Previewable @State var isDarkMode = true

    DarkModeToggle(isDarkMode: $isDarkMode)
        .darkModeStyle(.vivid)
        .frame(width: 260)
        .padding()
        .background(Color(red: 66 / 255, green: 66 / 255, blue: 66 / 255))
}
