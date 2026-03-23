import SwiftUI

struct BreathingExerciseView: View {
    @Environment(\.dismiss) var dismiss

    @State private var currentPhase: BreathPhase = .ready
    @State private var currentCycle = 0
    @State private var phaseTimeRemaining: Int = 0
    @State private var isRunning = false
    @State private var timer: Timer?

    // Fill: 0 = empty (offset down), 1 = full (offset 0)
    @State private var fillLevel: CGFloat = 0
    // Wave animation
    @State private var waveOffset: CGFloat = 0
    // Ring progress
    @State private var ringProgress: CGFloat = 0
    // Done view
    @State private var doneCheckScale: CGFloat = 0
    @State private var doneCheckOpacity: Double = 0
    // Ready view
    @State private var readyFill: CGFloat = 0
    // Flag: activeView should kick off the first fill on appear
    @State private var needsInitialFill = false

    @State var totalCycles: Int = 12
    @State var inhaleSeconds: Int = 5
    @State var holdSeconds: Int = 17
    @State var exhaleSeconds: Int = 9

    private let circleSize: CGFloat = 250

    enum BreathPhase: String {
        case ready = "Ready"
        case inhale = "Inhale"
        case hold = "Hold"
        case exhale = "Exhale"
        case done = "Complete"
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    if currentPhase == .ready {
                        readyView
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else if currentPhase == .done {
                        doneView
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        activeView
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .padding()
                .animation(.easeInOut(duration: 0.5), value: currentPhase)
            }
            .navigationTitle("Breathing Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        stopExercise()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(0.12)
        .animation(.easeInOut(duration: 1.5), value: currentPhase)
    }

    private var backgroundColors: [Color] {
        switch currentPhase {
        case .inhale: return [.blue, .cyan]
        case .hold: return [.purple, .indigo]
        case .exhale: return [.teal, .mint]
        case .done: return [.green, .mint]
        default: return [.blue, .purple]
        }
    }

    // MARK: - Ready View

    private var readyView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                    .frame(width: 130, height: 130)

                // Mini fill preview
                fillCircle(size: 124, level: readyFill, color: .blue)

                Image(systemName: "lungs.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue.opacity(0.8))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    readyFill = 0.7
                }
            }

            Text("Guided Breathing")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                timingStepper(label: "Inhale", value: $inhaleSeconds, color: .blue, range: 1...15)
                timingStepper(label: "Hold", value: $holdSeconds, color: .purple, range: 1...30)
                timingStepper(label: "Exhale", value: $exhaleSeconds, color: .teal, range: 1...20)

                Divider()

                timingStepper(label: "Cycles", value: $totalCycles, color: .gray, range: 1...30)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Spacer()

            Button {
                startExercise()
            } label: {
                Text("Start")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(14)
            }
        }
    }

    // MARK: - Reusable fill circle

    private func fillCircle(size: CGFloat, level: CGFloat, color: Color) -> some View {
        Circle()
            .fill(color.opacity(0.05))
            .frame(width: size, height: size)
            .overlay(
                // Full-size fill rect that slides up via offset
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.5), color.opacity(0.25)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: size, height: size)
                    // offset: when level=0, push down by full size (hidden below);
                    // when level=1, offset=0 (fully visible)
                    .offset(y: size * (1.0 - level))
            )
            .clipShape(Circle())
    }

    // MARK: - Active View

    private var activeView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                Text("Cycle \(currentCycle) of \(totalCycles)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .contentTransition(.numericText())

                HStack(spacing: 3) {
                    ForEach(0..<min(totalCycles, 20), id: \.self) { i in
                        Circle()
                            .fill(i < currentCycle ? phaseColor : Color.gray.opacity(0.3))
                            .frame(width: 4, height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentCycle)
                    }
                }
            }

            Spacer()

            ZStack {
                // Progress ring
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 4)
                    .frame(width: circleSize + 24, height: circleSize + 24)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        phaseColor.opacity(0.5),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: circleSize + 24, height: circleSize + 24)
                    .rotationEffect(.degrees(-90))

                // Container outline
                Circle()
                    .stroke(phaseColor.opacity(0.3), lineWidth: 3)
                    .frame(width: circleSize, height: circleSize)

                // Empty interior
                Circle()
                    .fill(phaseColor.opacity(0.03))
                    .frame(width: circleSize - 6, height: circleSize - 6)

                // THE FILL — slides up from bottom on inhale, slides down on exhale
                Circle()
                    .fill(Color.clear)
                    .frame(width: circleSize - 6, height: circleSize - 6)
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        phaseColor.opacity(0.55),
                                        phaseColor.opacity(0.3),
                                        phaseColor.opacity(0.15)
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: circleSize - 6, height: circleSize - 6)
                            .offset(y: (circleSize - 6) * (1.0 - fillLevel))
                    )
                    .clipShape(Circle())
                    .animation(.easeInOut(duration: currentAnimationDuration), value: fillLevel)

                // Wavy surface line
                if fillLevel > 0.03 && fillLevel < 0.97 {
                    WaveShape(offset: waveOffset, amplitude: currentPhase == .hold ? 5 : 3)
                        .fill(phaseColor.opacity(0.4))
                        .frame(width: circleSize - 6, height: 14)
                        .offset(y: ((circleSize - 6) / 2) - ((circleSize - 6) * fillLevel) + 7)
                        .clipShape(Circle().size(width: circleSize - 6, height: circleSize - 6))
                        .frame(width: circleSize - 6, height: circleSize - 6)
                        .animation(.easeInOut(duration: currentAnimationDuration), value: fillLevel)
                }

                // Glass highlight
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .frame(width: circleSize * 0.45, height: circleSize * 0.45)
                    .offset(x: -circleSize * 0.15, y: -circleSize * 0.15)
                    .allowsHitTesting(false)

                // Phase text
                VStack(spacing: 4) {
                    Text(currentPhase.rawValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(phaseColor)
                        .contentTransition(.interpolate)

                    Text("\(phaseTimeRemaining)")
                        .font(.system(size: 52, weight: .ultraLight, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: phaseTimeRemaining)
                }
            }

            Spacer()

            Text(phaseInstruction)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.5), value: currentPhase)

            Button {
                stopExercise()
            } label: {
                Text("Stop")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(14)
            }
        }
        .onAppear {
            if needsInitialFill {
                needsInitialFill = false
                // Now the view is on screen — kick off the fill animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    fillLevel = 1.0
                    ringProgress = 1.0
                    startWaveAnimation()
                    startTimer()
                }
            }
        }
    }

    // MARK: - Done View

    private var doneView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.green.opacity(0.2 - Double(i) * 0.05), lineWidth: 2)
                        .frame(width: CGFloat(100 + i * 40), height: CGFloat(100 + i * 40))
                        .scaleEffect(doneCheckScale)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.6)
                                .delay(Double(i) * 0.1),
                            value: doneCheckScale
                        )
                }

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(doneCheckScale)
                    .opacity(doneCheckOpacity)
            }

            Text("Well Done!")
                .font(.title)
                .fontWeight(.bold)
                .opacity(doneCheckOpacity)

            Text("You completed \(totalCycles) breathing cycles.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .opacity(doneCheckOpacity)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(14)
            }
            .opacity(doneCheckOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                doneCheckScale = 1.0
                doneCheckOpacity = 1.0
            }
        }
    }

    // MARK: - Helpers

    private func timingStepper(label: String, value: Binding<Int>, color: Color, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            Spacer()
            Button {
                if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundColor(color)
            }
            Text("\(value.wrappedValue)s")
                .font(.headline)
                .frame(width: 40)
                .contentTransition(.numericText())
            Button {
                if value.wrappedValue < range.upperBound { value.wrappedValue += 1 }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(color)
            }
        }
    }

    private var phaseColor: Color {
        switch currentPhase {
        case .inhale: return .blue
        case .hold: return .purple
        case .exhale: return .teal
        default: return .gray
        }
    }

    private var phaseInstruction: String {
        switch currentPhase {
        case .inhale: return "Breathe in slowly through your nose"
        case .hold: return "Hold your breath gently"
        case .exhale: return "Breathe out slowly through your mouth"
        default: return ""
        }
    }

    private var currentAnimationDuration: Double {
        switch currentPhase {
        case .inhale: return Double(inhaleSeconds)
        case .exhale: return Double(exhaleSeconds)
        default: return 0.5
        }
    }

    private func startExercise() {
        currentCycle = 1
        fillLevel = 0
        waveOffset = 0
        ringProgress = 0
        doneCheckScale = 0
        doneCheckOpacity = 0
        phaseTimeRemaining = inhaleSeconds
        isRunning = true
        needsInitialFill = true
        // Switch to inhale — activeView will appear and .onAppear triggers the fill
        currentPhase = .inhale
    }

    private func stopExercise() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        currentPhase = .ready
        fillLevel = 0
        waveOffset = 0
        ringProgress = 0
        readyFill = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                readyFill = 0.7
            }
        }
    }

    private func startWaveAnimation() {
        waveOffset = 0
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            waveOffset = .pi * 2
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if phaseTimeRemaining > 1 {
                phaseTimeRemaining -= 1
            } else {
                advancePhase()
            }
        }
    }

    private func beginPhase(_ phase: BreathPhase) {
        timer?.invalidate()
        currentPhase = phase
        ringProgress = 0

        switch phase {
        case .inhale:
            phaseTimeRemaining = inhaleSeconds
            // fillLevel is already 0 from exhale ending — animate to 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                fillLevel = 1.0
                withAnimation(.easeInOut(duration: Double(inhaleSeconds))) {
                    ringProgress = 1.0
                }
                startWaveAnimation()
                startTimer()
            }
            return // timer started in the async block

        case .hold:
            phaseTimeRemaining = holdSeconds
            // fillLevel stays at 1.0 (full)
            waveOffset = 0
            withAnimation(.easeInOut(duration: Double(holdSeconds))) {
                ringProgress = 1.0
            }
            startWaveAnimation()

        case .exhale:
            phaseTimeRemaining = exhaleSeconds
            // Drain from 1 → 0
            fillLevel = 0
            waveOffset = 0
            withAnimation(.easeInOut(duration: Double(exhaleSeconds))) {
                ringProgress = 1.0
            }
            startWaveAnimation()

        default:
            return
        }

        startTimer()
    }

    private func advancePhase() {
        timer?.invalidate()
        switch currentPhase {
        case .inhale:
            beginPhase(.hold)
        case .hold:
            beginPhase(.exhale)
        case .exhale:
            if currentCycle < totalCycles {
                currentCycle += 1
                beginPhase(.inhale)
            } else {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentPhase = .done
                }
                isRunning = false
            }
        default:
            break
        }
    }
}

// MARK: - Wave Shape

struct WaveShape: Shape {
    var offset: CGFloat
    var amplitude: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2

        path.move(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let y = midY + sin((relativeX * .pi * 2) + offset) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}
