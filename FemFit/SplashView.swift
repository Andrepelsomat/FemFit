// SplashView.swift
// FemFit – Splash Screen beim App-Start
// Neu in Xcode: File > New > File > Swift File > "SplashView"

import SwiftUI

struct SplashView: View {

    @State private var logoScale: CGFloat     = 0.6
    @State private var logoOpacity: Double    = 0
    @State private var textOpacity: Double    = 0
    @State private var taglineOpacity: Double = 0
    @State private var isFinished = false

    var body: some View {
        if isFinished {
            ContentView()
        } else {
            splashContent
        }
    }

    var splashContent: some View {
        ZStack {
            // Hintergrund Gradient
            LinearGradient(
                colors: [
                    Color(hex: "#1a0a12"),
                    Color(hex: "#2d1020"),
                    Color(hex: "#1a0a12")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── Logo-Bereich ──
                VStack(spacing: 20) {

                    // App Icon / Logo
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#E84393"), Color(hex: "#9B1B6E")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                            .shadow(color: Color(hex: "#E84393").opacity(0.5), radius: 20, y: 8)

                        VStack(spacing: 2) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(.white)
                            Image(systemName: "moon.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    // App Name
                    VStack(spacing: 6) {
                        Text("FemFit")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(textOpacity)

                        Text("Training. Zyklus. Fortschritt.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .opacity(taglineOpacity)
                    }
                }

                Spacer()

                // Unten: Ladeindikator
                VStack(spacing: 8) {
                    ProgressView()
                        .tint(Color(hex: "#E84393"))
                        .opacity(taglineOpacity)
                    Text("wird geladen...")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.3))
                        .opacity(taglineOpacity)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            animateSplash()
        }
    }

    func animateSplash() {
        // Logo einblenden
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            logoScale   = 1.0
            logoOpacity = 1.0
        }

        // Text einblenden
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            textOpacity = 1.0
        }

        // Tagline + Loader einblenden
        withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
            taglineOpacity = 1.0
        }

        // Nach 2 Sekunden zur ContentView wechseln
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isFinished = true
            }
        }
    }
}
