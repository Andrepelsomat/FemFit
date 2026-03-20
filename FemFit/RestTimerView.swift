// RestTimerView.swift
// FemFit – Pause-Timer zwischen Sätzen
// Neu in Xcode: File > New > File > Swift File > "RestTimerView"

import SwiftUI
import AudioToolbox

struct RestTimerView: View {

    @Binding var isShowing: Bool
    let setNumber: Int

    var cycleManager = CycleManager.shared

    // Standard-Pausenzeit – Periode = kürzer weil weniger Belastung
    @State private var totalSeconds: Int = 90
    @State private var secondsLeft: Int  = 90
    @State private var isRunning  = true
    @State private var timer: Timer? = nil
    @State private var pulse = false

    let presets = [30, 60, 90, 120, 180]

    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 1 }
        return 1.0 - Double(secondsLeft) / Double(totalSeconds)
    }

    var timeString: String {
        let m = secondsLeft / 60
        let s = secondsLeft % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        ZStack {
            // Hintergrund
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { skip() }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {

                    // ── Titel ──
                    VStack(spacing: 6) {
                        Text("Pause")
                            .font(.title2).fontWeight(.bold)
                        Text("Satz \(setNumber) abgeschlossen 💪")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // ── Timer Ring ──
                    ZStack {
                        // Hintergrund Ring
                        Circle()
                            .stroke(Color(uiColor: UIColor.systemGray5), lineWidth: 12)
                            .frame(width: 180, height: 180)

                        // Fortschritts Ring
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                accentColor,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: progress)

                        // Zeit-Anzeige
                        VStack(spacing: 4) {
                            Text(timeString)
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundColor(secondsLeft <= 5 ? .red : .primary)
                                .scaleEffect(pulse ? 1.08 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: pulse)

                            Text(isRunning ? "läuft..." : "pausiert")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // ── Preset-Buttons ──
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.self) { sec in
                            Button {
                                setTimer(seconds: sec)
                            } label: {
                                Text(sec < 60 ? "\(sec)s" : "\(sec/60)m")
                                    .font(.caption).fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        totalSeconds == sec
                                        ? accentColor
                                        : Color(uiColor: UIColor.systemGray5)
                                    )
                                    .foregroundColor(totalSeconds == sec ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }

                    // ── Kontroll-Buttons ──
                    HStack(spacing: 16) {

                        // Pause / Play
                        Button {
                            isRunning ? pauseTimer() : resumeTimer()
                        } label: {
                            Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.secondary)
                        }

                        // Skip
                        Button {
                            skip()
                        } label: {
                            Text("Überspringen")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(accentColor)
                                .cornerRadius(14)
                        }

                        // +30 Sekunden
                        Button {
                            secondsLeft = min(secondsLeft + 30, 600)
                            totalSeconds = max(totalSeconds, secondsLeft)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(28)
                .background(Color(uiColor: UIColor.systemBackground))
                .cornerRadius(28)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Perioden-Empfehlung: kürzere Pause
            let recommended = cycleManager.isInPeriod ? 60 : 90
            setTimer(seconds: recommended)
        }
        .onDisappear {
            stopTimer()
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Timer Logik
    // ───────────────────────────────────────────

    func setTimer(seconds: Int) {
        stopTimer()
        totalSeconds = seconds
        secondsLeft  = seconds
        isRunning    = true
        startTimer()
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsLeft > 0 {
                secondsLeft -= 1
                // Puls-Animation in den letzten 5 Sekunden
                if secondsLeft <= 5 {
                    withAnimation { pulse.toggle() }
                }
            } else {
                timerFinished()
            }
        }
    }

    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func resumeTimer() {
        isRunning = true
        startTimer()
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func skip() {
        stopTimer()
        withAnimation(.spring(response: 0.3)) {
            isShowing = false
        }
    }

    func timerFinished() {
        stopTimer()
        // Vibration
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AudioServicesPlaySystemSound(1521) // leichtes Haptic-Feedback

        // Kurz warten dann automatisch schließen
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.3)) {
                isShowing = false
            }
        }
    }
}
