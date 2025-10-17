//
//  EnergyStoreView.swift
//  Unknown Detective
//
//  Created by GitHub Copilot on 17.10.2025.
//

import SwiftUI
import StoreKit

struct EnergyStoreView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    @State private var isRewarding = false
    @State private var showReceiptAlert = false
    @State private var alertMessage = ""

    @StateObject private var store = StoreKitManager.shared

    private let packs = EnergyPack.samplePacks

    var body: some View {
        NavigationStack {
            List {
                statusSection
                rewardedSection
                packsSection
                subscriptionSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [NoirTheme.backgroundTop, NoirTheme.backgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Enerji Mağazası")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .alert(isPresented: $showReceiptAlert) {
                Alert(title: Text("Bilgi"), message: Text(alertMessage), dismissButton: .default(Text("Tamam")))
            }
        }
        .tint(NoirTheme.accent)
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .onAppear {
            Haptics.light()
            Task { @MainActor in
                await store.loadProducts()
                let active = await store.hasActiveDetectivePlus()
                gameState.setDetectivePlus(active)
                store.observeTransactionUpdates { tx in
                    if tx.productID == StoreKitManager.ProductID.detectivePlusMonthly.rawValue ||
                        tx.productID == StoreKitManager.ProductID.detectivePlusYearly.rawValue {
                        Task { @MainActor in gameState.setDetectivePlus(true) }
                    }
                }
            }
        }
    }

    private var statusSection: some View {
        Section("Durum") {
            HStack {
                Label("Mevcut Enerji", systemImage: "bolt.fill")
                Spacer()
                Text("\(gameState.energy)/\(gameState.maxEnergy)")
                    .font(.headline.monospacedDigit())
            }
            .foregroundStyle(NoirTheme.neon)
            HStack {
                Label("İpucu Kredisi", systemImage: "lightbulb.fill")
                Spacer()
                Text(gameState.hasDetectivePlus ? "Sınırsız" : "\(gameState.hintCredits)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(gameState.hasDetectivePlus ? NoirTheme.neon : NoirTheme.caution)
            }
            if gameState.energy >= gameState.maxEnergy {
                Text("Enerjin zaten maksimum.")
                    .font(.caption)
                    .foregroundStyle(NoirTheme.subtleText)
            }
        }
        .headerProminence(.increased)
    }

    private var rewardedSection: some View {
        Section("Ödüllü Reklam") {
            Button {
                triggerRewardedEnergy()
            } label: {
                HStack {
                    Image(systemName: "play.rectangle.fill")
                        .foregroundStyle(NoirTheme.neon)
                    Text("Reklam izle ve +1 enerji kazan")
                    Spacer()
                    if isRewarding {
                        ProgressView()
                            .tint(NoirTheme.accent)
                    }
                }
                .foregroundStyle(Color.white)
            }
            .disabled(isRewarding)
            Button {
                triggerRewardedHint()
            } label: {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundStyle(NoirTheme.caution)
                    Text("Reklam izle ve +1 ipucu kredisi kazan")
                    Spacer()
                    if isRewarding {
                        ProgressView()
                            .tint(NoirTheme.accent)
                    }
                }
                .foregroundStyle(Color.white)
            }
            .disabled(isRewarding || gameState.hasDetectivePlus)
            Text("Reklamlar 24 saatte en fazla 3 kez izlenebilir. Simülasyon amaçlı süre 3 saniye.")
                .font(.caption)
                .foregroundStyle(NoirTheme.subtleText)
        }
    }

    private var packsSection: some View {
        Section("Enerji Paketleri") {
            ForEach(packs) { pack in
                Button {
                    Task { await purchase(pack: pack) }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pack.title)
                                .font(.subheadline.weight(.semibold))
                            Text(pack.subtitle)
                                .font(.caption)
                                .foregroundStyle(NoirTheme.subtleText)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(price(for: pack))
                                .font(.subheadline.weight(.bold))
                            HStack(spacing: 4) {
                                Image(systemName: "bolt")
                                Text("+\(pack.energy)")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(NoirTheme.subtleText)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .disabled(gameState.energy >= gameState.maxEnergy || store.isLoading)
            }
            if let err = store.lastError {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            Text("Satın alımlar StoreKit 2 ile doğrulanacak. Bu makette sadece yerel enerji artırımı yapılır.")
                .font(.caption)
                .foregroundStyle(NoirTheme.subtleText)
        }
    }

    private var subscriptionSection: some View {
        Section("Detective Plus") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sınırsız vaka, sınırsız enerji")
                    .font(.subheadline.weight(.semibold))
                Text("49₺/ay veya 499₺/yıl. Premium vakalara erişim ve sınırsız ipucu.")
                    .font(.caption)
                    .foregroundStyle(NoirTheme.subtleText)
                HStack {
                    Button { Task { await startSubscription(.detectivePlusMonthly) } } label: {
                        Text(buttonTitle(for: .detectivePlusMonthly))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(NoirTheme.neon)

                    Button { Task { await startSubscription(.detectivePlusYearly) } } label: {
                        Text(buttonTitle(for: .detectivePlusYearly))
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func price(for pack: EnergyPack) -> String {
        let id: StoreKitManager.ProductID
        switch pack.id {
        case "pack.small": id = .packSmall
        case "pack.medium": id = .packMedium
        case "pack.large": id = .packLarge
        default: return pack.price
        }
        if let product = store.products[id] {
            return product.displayPrice
        }
        return pack.price
    }

    private func buttonTitle(for id: StoreKitManager.ProductID) -> String {
        if let product = store.products[id] {
            switch id {
            case .detectivePlusMonthly:
                return String(format: NSLocalizedString("Aylık %@", comment: "Monthly price"), product.displayPrice)
            case .detectivePlusYearly:
                return String(format: NSLocalizedString("Yıllık %@", comment: "Yearly price"), product.displayPrice)
            default:
                return product.displayPrice
            }
        }
        switch id {
        case .detectivePlusMonthly:
            return "Aylık"
        case .detectivePlusYearly:
            return "Yıllık"
        default:
            return "Satın Al"
        }
    }

    private func startSubscription(_ id: StoreKitManager.ProductID) async {
        let ok = await store.purchase(id)
        if ok {
            alertMessage = "Abonelik etkinleştirildi: Detective Plus aktif."
            showReceiptAlert = true
            gameState.setDetectivePlus(true)
            Haptics.success()
        } else if let err = store.lastError {
            alertMessage = err
            showReceiptAlert = true
            Haptics.warning()
        }
    }

    private func triggerRewardedEnergy() {
        guard !isRewarding else { return }
        isRewarding = true
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                gameState.addEnergy(1)
                alertMessage = "Reklam ödülü eklendi: +1 enerji."
                showReceiptAlert = true
                isRewarding = false
                Haptics.success()
            }
        }
    }

    private func triggerRewardedHint() {
        guard !isRewarding else { return }
        isRewarding = true
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                gameState.addHintCredits(1)
                alertMessage = "Reklam ödülü eklendi: +1 ipucu kredisi."
                showReceiptAlert = true
                isRewarding = false
                Haptics.success()
            }
        }
    }

    private func purchase(pack: EnergyPack) async {
        guard gameState.energy < gameState.maxEnergy else {
            alertMessage = "Enerji maksimum, satın alma gerekmiyor."
            showReceiptAlert = true
            Haptics.warning()
            return
        }
        let id: StoreKitManager.ProductID?
        switch pack.id {
        case "pack.small": id = .packSmall
        case "pack.medium": id = .packMedium
        case "pack.large": id = .packLarge
        default: id = nil
        }
        if let id, let _ = store.products[id] {
            let ok = await store.purchase(id)
            if ok {
                gameState.addEnergy(pack.energy, allowOverflow: true)
                alertMessage = "\(pack.title) satın alındı: +\(pack.energy) enerji."
                showReceiptAlert = true
                Haptics.success()
            } else if let err = store.lastError {
                alertMessage = err
                showReceiptAlert = true
                Haptics.warning()
            }
        } else {
            // Fallback if products not loaded
            gameState.addEnergy(pack.energy, allowOverflow: true)
            alertMessage = "\(pack.title) satın alındı: +\(pack.energy) enerji."
            showReceiptAlert = true
            Haptics.success()
        }
    }
}

private struct EnergyPack: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let price: String
    let energy: Int

    static let samplePacks: [EnergyPack] = [
        EnergyPack(id: "pack.small", title: "Günlük Takviye", subtitle: "3 ek vaka hakkı", price: "₺19", energy: 3),
        EnergyPack(id: "pack.medium", title: "Araştırmacı Paketi", subtitle: "5 ek vaka hakkı", price: "₺39", energy: 5),
        EnergyPack(id: "pack.large", title: "Operasyon Paketi", subtitle: "10 ek vaka hakkı", price: "₺89", energy: 10)
    ]
}

#Preview {
    EnergyStoreView(gameState: GameState(initialMaxEnergy: 12, dailyEnergyAllowance: 3, dailyHintAllowance: 2, defaults: UserDefaults(suiteName: "preview") ?? .standard))
}
