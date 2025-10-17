// filepath: /Users/mansur/projects/nokari/Unknown Detective/Unknown Detective/SplashView.swift
//
//  SplashView.swift
//  Unknown Detective
//
//  Simple animated splash screen overlay shown on launch.

import SwiftUI

struct SplashView: View {
    let onFinish: () -> Void
    
    @State private var appear = false

    private var versionLabel: String {
        let info = Bundle.main.infoDictionary
        let version = (info?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let build = (info?["CFBundleVersion"] as? String) ?? "1"
        return "v\(version) (\(build))"
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [NoirTheme.backgroundTop, NoirTheme.backgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(NoirTheme.neon, NoirTheme.accent)
                    .font(.system(size: 72, weight: .bold))
                    .scaleEffect(appear ? 1.0 : 0.8)
                    .shadow(color: NoirTheme.accent.opacity(0.25), radius: 12, x: 0, y: 8)

                Text("Unknown Detective")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .opacity(appear ? 1 : 0)

                Text("Karanlığı aydınlığa çevir.")
                    .font(.footnote)
                    .foregroundStyle(NoirTheme.subtleText)
                    .opacity(appear ? 1 : 0)

                Text(versionLabel)
                    .font(.caption2)
                    .foregroundStyle(NoirTheme.subtleText)
                    .opacity(appear ? 0.9 : 0)
                    .padding(.top, 4)
            }
            .padding(24)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) { onFinish() }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { appear = true }
            // Auto dismiss after a short delay
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                withAnimation(.easeInOut(duration: 0.35)) { onFinish() }
            }
        }
    }
}

#Preview {
    SplashView(onFinish: {})
}
