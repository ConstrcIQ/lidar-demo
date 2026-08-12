import SwiftUI

struct ContentView: View {
    var body: some View {
        if ScanSession.deviceHasLiDAR {
            ScannerScreen()
        } else {
            UnsupportedScreen()
        }
    }
}

// MARK: - Hovedskærm

struct ScannerScreen: View {
    @StateObject private var session = ScanSession()

    var body: some View {
        ZStack {
            ARViewContainer(session: session)
                .ignoresSafeArea()

            Crosshair(distance: session.centerDistance, isRunning: session.isRunning)

            VStack {
                StatusBar(session: session)
                Spacer()
                ControlBar(session: session)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .statusBarHidden()
    }
}

// MARK: - Sigtekorn og afstandsvisning

private struct Crosshair: View {
    let distance: Float?
    let isRunning: Bool

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.9), lineWidth: 2)
                    .frame(width: 26, height: 26)
                Circle()
                    .fill(.white)
                    .frame(width: 3, height: 3)
            }
            .shadow(radius: 3)

            if isRunning {
                Text(distanceLabel)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.35), in: Capsule())
            }
        }
    }

    private var distanceLabel: String {
        guard let distance else { return "– – –" }
        return String(format: "%.2f m", distance)
    }
}

// MARK: - Statuslinje

private struct StatusBar: View {
    @ObservedObject var session: ScanSession

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.statusText)
                    .font(.subheadline.weight(.medium))
                Text("\(session.meshChunkCount) brikker · \(formattedTriangles) trekanter")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .monospacedDigit()
            }
            Spacer()
            Toggle("", isOn: $session.showMesh)
                .labelsHidden()
                .tint(.green)
        }
        .foregroundStyle(.white)
        .padding(12)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.top, 8)
    }

    private var formattedTriangles: String {
        session.triangleCount.formatted(.number.grouping(.automatic))
    }
}

// MARK: - Knapper

private struct ControlBar: View {
    @ObservedObject var session: ScanSession

    var body: some View {
        HStack(spacing: 12) {
            Button {
                session.isRunning ? session.pause() : session.start()
            } label: {
                Label(session.isRunning ? "Pause" : "Start",
                      systemImage: session.isRunning ? "pause.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButton(tint: session.isRunning ? .orange : .green))

            Button {
                session.reset()
            } label: {
                Label("Nulstil", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButton(tint: .white.opacity(0.18)))
            .disabled(!session.isRunning)
        }
    }
}

private struct PillButton: ButtonStyle {
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

// MARK: - Enheder uden LiDAR

private struct UnsupportedScreen: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
            Text("Ingen LiDAR-scanner")
                .font(.title2.weight(.semibold))
            Text("Appen kræver en iPhone Pro-model (12 Pro eller nyere) eller en iPad Pro med LiDAR.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }
}
