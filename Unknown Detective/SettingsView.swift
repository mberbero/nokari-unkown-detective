//
//  SettingsView.swift
//  Unknown Detective
//
//  Lightweight settings and debug utilities.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    @State private var showResetConfirm = false
    @State private var infoMessage: String?
    @State private var showInfoAlert = false

    @StateObject private var notifications = NotificationsManager.shared
    @State private var notificationsEnabled: Bool = AppPreferences.notificationsEnabled

    var body: some View {
        NavigationStack {
            List {
                statusSection
                preferencesSection
                notificationsSection
                gameplaySection
                debugSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Ayarlar")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .alert("Bilgi", isPresented: $showInfoAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(infoMessage ?? "")
            }
            .confirmationDialog("İlerlemeyi sıfırlamak istediğinden emin misin?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Evet, sıfırla", role: .destructive) { performReset() }
                Button("Vazgeç", role: .cancel) {}
            }
        }
        .onAppear { Haptics.light(); Task { await notifications.refreshAuthorizationStatus() } }
    }

    private var statusSection: some View {
        Section("Durum") {
            HStack {
                Label("Enerji", systemImage: "bolt.fill")
                Spacer()
                Text("\(gameState.energy)/\(gameState.maxEnergy)")
                    .font(.headline.monospacedDigit())
            }
            HStack {
                Label("İpucu", systemImage: "lightbulb.fill")
                Spacer()
                Text(gameState.hasDetectivePlus ? "Sınırsız" : "\(gameState.hintCredits)")
                    .font(.headline.monospacedDigit())
            }
            HStack {
                Label("Detective Plus", systemImage: "infinity")
                Spacer()
                Toggle("", isOn: detectivePlusBinding)
                    .labelsHidden()
            }
        }
    }

    private var preferencesSection: some View {
        Section("Tercihler") {
            Toggle(isOn: $hapticsEnabled) {
                Label("Haptik geri bildirim", systemImage: "waveform")
            }
        }
    }

    private var notificationsSection: some View {
        Section("Bildirimler") {
            Toggle(isOn: Binding(
                get: { notificationsEnabled },
                set: { newValue in
                    notificationsEnabled = newValue
                    AppPreferences.notificationsEnabled = newValue
                    if newValue {
                        Task {
                            let granted = await notifications.requestAuthorization()
                            if granted {
                                notifications.scheduleDailyReminder(at: gameState.nextRefillDate)
                                showMessage("Günlük hatırlatma ayarlandı.")
                            } else {
                                showMessage("Bildirim izni verilmedi.")
                                notificationsEnabled = false
                                AppPreferences.notificationsEnabled = false
                            }
                        }
                    } else {
                        notifications.cancelDailyReminder()
                    }
                }
            )) {
                Label("Günlük bonus/yenileme hatırlat", systemImage: "bell")
            }
            Text(statusLine)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var gameplaySection: some View {
        Section("Oynanış") {
            Button {
                gameState.refillNow()
                Haptics.success()
                showMessage("Enerji ve ipucu günlük seviyeye getirildi.")
            } label: {
                Label("Günlük yenilemeyi uygula", systemImage: "arrow.triangle.2.circlepath")
            }

            Button {
                gameState.increaseMaxEnergy(by: 5)
                gameState.addEnergy(5, allowOverflow: false)
                Haptics.success()
                showMessage("Maksimum enerji +5 artırıldı.")
            } label: {
                Label("Maksimum enerji +5", systemImage: "bolt.circle")
            }

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("İlerlemeyi sıfırla", systemImage: "trash")
            }
        }
    }

    private var debugSection: some View {
        Section(header: Text("Debug"), footer: Text("Bazı ayarlar geliştirici amaçlıdır ve ilerleme kaydını etkileyebilir.")) {
            Text("Sonraki yenileme: \(formattedNextRefill)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var detectivePlusBinding: Binding<Bool> {
        Binding(
            get: { gameState.hasDetectivePlus },
            set: { gameState.setDetectivePlus($0); Haptics.light() }
        )
    }

    private var formattedNextRefill: String {
        let date = gameState.nextRefillDate
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var statusLine: String {
        switch notifications.authorizationStatus {
        case .authorized, .provisional:
            return "Bildirim izni: açık"
        case .denied:
            return "Bildirim izni: kapalı"
        case .ephemeral:
            return "Bildirim izni: geçici"
        case .notDetermined:
            return "Bildirim izni: sorulmadı"
        @unknown default:
            return "Bildirim izni: bilinmiyor"
        }
    }

    private func performReset() {
        gameState.resetProgress()
        ActiveSessionStore.clear()
        Haptics.warning()
        showMessage("İlerleme sıfırlandı.")
    }

    private func showMessage(_ text: String) {
        infoMessage = text
        showInfoAlert = true
    }
}

#Preview {
    SettingsView(gameState: GameState())
}
