import SwiftUI

enum DemoMode: String, CaseIterable, Identifiable {
    case scan = "Scan rum"
    case wave = "Find vink"
    var id: String { rawValue }
}

struct ContentView: View {
    @State private var mode: DemoMode = .scan

    var body: some View {
        if ScanSession.deviceHasLiDAR {
            ZStack(alignment: .top) {
                // .id() tvinger SwiftUI til at kassere den gamle skærm helt, når man
                // skifter tilstand. Det er nødvendigt: to AR-sessioner kan ikke køre
                // samtidig, og den gamle skal nå at lukke ned, før den nye starter.
                Group {
                    switch mode {
                    case .scan: ScannerScreen()
                    case .wave: TrackingScreen()
                    }
                }
                .id(mode)

                Picker("Tilstand", selection: $mode) {
                    ForEach(DemoMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
        } else {
            UnsupportedScreen()
        }
    }
}

// MARK: - Rumscanning

struct ScannerScreen: View {
    @StateObject private var session = ScanSession()

    var body: some View {
        ZStack {
            ARViewContainer(arView: session.arView)
                .ignoresSafeArea()

            Crosshair(distance: session.centerDistance, isRunning: session.isRunning)

            VStack {
                Spacer()
                StatusCard {
                    Text(session.statusText)
                        .font(.subheadline.weight(.medium))
                    Text("\(session.meshChunkCount) brikker · \(session.triangleCount.formatted()) trekanter")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .monospacedDigit()
                }
                ControlBar(isRunning: session.isRunning,
                           onToggle: { session.isRunning ? session.pause() : session.start() },
                           onReset: { session.reset() })
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .statusBarHidden()
        .onDisappear { session.pause() }
    }
}

// MARK: - Personsporing og vink

struct TrackingScreen: View {
    @StateObject private var session = TrackingSession()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ARViewContainer(arView: session.arView)
                    .ignoresSafeArea()

                TrackingOverlay(people: session.people, size: proxy.size)
                    .allowsHitTesting(false)

                VStack {
                    Spacer()
                    StatusCard {
                        Text(session.statusText)
                            .font(.subheadline.weight(.medium))
                        Text(String(format: "%.0f analyser/sek · grøn = begge sensorer enige",
                                    session.analysisRate))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .monospacedDigit()
                    }
                    ControlBar(isRunning: session.isRunning,
                               onToggle: { session.isRunning ? session.pause() : session.start() },
                               onReset: { session.pause(); session.start() })
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .onAppear { session.setViewport(proxy.size) }
            .onChange(of: proxy.size) { _, newSize in session.setViewport(newSize) }
        }
        .statusBarHidden()
        .onDisappear { session.pause() }
    }
}

// MARK: - Fælles dele

struct Crosshair: View {
    let distance: Float?
    let isRunning: Bool

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().stroke(.white.opacity(0.9), lineWidth: 2).frame(width: 26, height: 26)
                Circle().fill(.white).frame(width: 3, height: 3)
            }
            .shadow(radius: 3)

            if isRunning {
                Text(distance.map { String(format: "%.2f m", $0) } ?? "– – –")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.35), in: Capsule())
            }
        }
    }
}

struct StatusCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.white)
            .padding(12)
            .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.bottom, 10)
    }
}

struct ControlBar: View {
    let isRunning: Bool
    let onToggle: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Label(isRunning ? "Pause" : "Start",
                      systemImage: isRunning ? "pause.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButton(tint: isRunning ? .orange : .green))

            Button(action: onReset) {
                Label("Nulstil", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButton(tint: .white.opacity(0.18)))
            .disabled(!isRunning)
        }
    }
}

struct PillButton: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .background(tint, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct UnsupportedScreen: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 44))
            Text("Ingen LiDAR-scanner").font(.title2.weight(.semibold))
            Text("Appen kræver en iPhone Pro-model (12 Pro eller nyere) eller en iPad Pro med LiDAR.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }
}
