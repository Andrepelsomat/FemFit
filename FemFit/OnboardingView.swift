// OnboardingView.swift
// FemFit – Onboarding beim ersten App-Start
// Neu in Xcode: File > New > File > Swift File > "OnboardingView"

import SwiftUI

struct OnboardingView: View {

    @AppStorage("onboardingDone") var onboardingDone = false
    @AppStorage("userName")       var userName       = ""

    var cycleManager = CycleManager.shared

    @State private var currentPage  = 0
    @State private var nameInput    = ""
    @State private var selectedCycleLength  = 28
    @State private var selectedPeriodLength = 5

    let accentPink  = Color(hex: "#E84393")
    let accentGreen = Color(hex: "#1D9E75")

    var body: some View {
        ZStack {
            // Hintergrund
            Color(hex: "#1a0a12").ignoresSafeArea()

            VStack(spacing: 0) {

                // Fortschritts-Punkte
                HStack(spacing: 8) {
                    ForEach(0..<4) { i in
                        Capsule()
                            .fill(i == currentPage ? accentPink : Color.white.opacity(0.3))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 60)

                Spacer()

                // Page Content
                Group {
                    switch currentPage {
                    case 0: page1
                    case 1: page2
                    case 2: page3
                    case 3: page4
                    default: page1
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentPage)

                Spacer()

                // Weiter-Button
                Button {
                    if currentPage < 3 {
                        withAnimation(.spring(response: 0.4)) {
                            currentPage += 1
                        }
                    } else {
                        finishOnboarding()
                    }
                } label: {
                    Text(currentPage == 3 ? "Loslegen! 💪" : "Weiter")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            currentPage == 3 ? accentPink : accentPink.opacity(0.8)
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 50)
                .disabled(currentPage == 1 && nameInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // ── Seite 1: Willkommen ──
    var page1: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(accentPink.opacity(0.2))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(accentPink.opacity(0.1))
                    .frame(width: 180, height: 180)
                VStack(spacing: 4) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(accentPink)
                    Image(systemName: "moon.fill")
                        .font(.system(size: 20))
                        .foregroundColor(accentPink.opacity(0.7))
                }
            }

            VStack(spacing: 12) {
                Text("Willkommen bei FemFit")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Die erste Fitness-App die deinen Zyklus wirklich versteht – und deine Gewichte anpasst.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 28)
    }

    // ── Seite 2: Name eingeben ──
    var page2: some View {
        VStack(spacing: 28) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(accentPink)

            VStack(spacing: 12) {
                Text("Wie heißt du?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Damit FemFit dich persönlich ansprechen kann.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            TextField("Dein Name...", text: $nameInput)
                .font(.title3)
                .foregroundColor(.white)
                .padding(16)
                .background(Color.white.opacity(0.1))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(nameInput.isEmpty ? Color.white.opacity(0.2) : accentPink, lineWidth: 1.5)
                )
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 28)
    }

    // ── Seite 3: Zyklus einstellen ──
    var page3: some View {
        VStack(spacing: 28) {
            Image(systemName: "calendar.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(accentPink)

            VStack(spacing: 12) {
                Text("Dein Zyklus")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("FemFit passt deine Trainingsgewichte automatisch an deinen Zyklus an.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 20) {
                // Zykluslänge
                VStack(spacing: 8) {
                    HStack {
                        Text("Zykluslänge")
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("\(selectedCycleLength) Tage")
                            .fontWeight(.semibold)
                            .foregroundColor(accentGreen)
                    }
                    Slider(value: Binding(
                        get: { Double(selectedCycleLength) },
                        set: { selectedCycleLength = Int($0) }
                    ), in: 21...35, step: 1)
                    .tint(accentGreen)
                }
                .padding(16)
                .background(Color.white.opacity(0.08))
                .cornerRadius(14)

                // Periodenlänge
                VStack(spacing: 8) {
                    HStack {
                        Text("Perioden-Länge")
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("\(selectedPeriodLength) Tage")
                            .fontWeight(.semibold)
                            .foregroundColor(accentPink)
                    }
                    Slider(value: Binding(
                        get: { Double(selectedPeriodLength) },
                        set: { selectedPeriodLength = Int($0) }
                    ), in: 2...10, step: 1)
                    .tint(accentPink)
                }
                .padding(16)
                .background(Color.white.opacity(0.08))
                .cornerRadius(14)
            }
        }
        .padding(.horizontal, 28)
    }

    // ── Seite 4: Fertig ──
    var page4: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(accentGreen.opacity(0.2))
                    .frame(width: 140, height: 140)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(accentGreen)
            }

            VStack(spacing: 12) {
                Text("Alles bereit\(nameInput.isEmpty ? "" : ", \(nameInput)")! 🎉")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Du kannst jetzt dein erstes Trainingsprogramm erstellen und anfangen zu tracken.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            // Zusammenfassung
            VStack(spacing: 12) {
                summaryRow(icon: "person.fill",         text: nameInput.isEmpty ? "Anonym" : nameInput,            color: accentPink)
                summaryRow(icon: "arrow.clockwise",     text: "Zyklus: \(selectedCycleLength) Tage",              color: accentGreen)
                summaryRow(icon: "moon.fill",           text: "Periode: \(selectedPeriodLength) Tage",            color: accentPink)
            }
            .padding(16)
            .background(Color.white.opacity(0.08))
            .cornerRadius(16)
        }
        .padding(.horizontal, 28)
    }

    func summaryRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .foregroundColor(.white.opacity(0.9))
            Spacer()
        }
        .font(.subheadline)
    }

    func finishOnboarding() {
        // Einstellungen speichern
        userName = nameInput
        cycleManager.cycleLength  = selectedCycleLength
        cycleManager.periodLength = selectedPeriodLength
        cycleManager.checkAndUpdateCycle()

        withAnimation(.easeInOut(duration: 0.4)) {
            onboardingDone = true
        }
    }
}
