//
//  CaseSessionView.swift
//  Unknown Detective
//
//  Created by GitHub Copilot on 17.10.2025.
//

import SwiftUI

struct CaseSessionView: View {
    @ObservedObject var viewModel: CaseSessionViewModel
    @EnvironmentObject private var gameState: GameState
    private let bottomID = "conversationBottom"
    @State private var showHintPaywall = false
    @State private var pendingSnapshot: CaseSnapshot?

    var body: some View {
        VStack(spacing: 0) {
            if let snapshot = viewModel.snapshot {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            CaseHeaderView(snapshot: snapshot)
                            if shouldShowHintBanner(for: snapshot) {
                                HintBanner(hints: viewModel.hints, hasDetectivePlus: gameState.hasDetectivePlus, isCaseClosed: isCaseClosed(snapshot)) {
                                    pendingSnapshot = snapshot
                                    showHintPaywall = true
                                }
                            }
                            SuspectsSection(suspects: snapshot.suspects)
                            CluesSection(clues: snapshot.clues)
                            HintsSection(hints: viewModel.hints)
                            ConversationSection(turns: snapshot.turns)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                        Color.clear
                            .frame(height: 1)
                            .id(bottomID)
                    }
                    .background(Color(.systemGroupedBackground))
                    .onAppear {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                    .onChangeCompat(of: snapshot.turns.last?.id) {
                        withAnimation {
                            proxy.scrollTo(bottomID, anchor: .bottom)
                        }
                    }
                }
                Divider()
                InputBar(
                    text: $viewModel.inputText,
                    isLoading: viewModel.isLoading,
                    onSubmit: viewModel.sendQuestion
                )
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            } else {
                Spacer()
                ProgressView("Vaka başlatılıyor...")
                Spacer()
            }
        }
        .navigationTitle(viewModel.snapshot?.title ?? viewModel.caseType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.start() }
        .alert(isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
            Alert(
                title: Text("Bir hata oluştu"),
                message: Text(viewModel.errorMessage ?? "Bilinmeyen hata"),
                dismissButton: .default(Text("Tamam"))
            )
        }
        .sheet(isPresented: $showHintPaywall) {
            if let snapshot = pendingSnapshot {
                HintPaywallView(snapshot: snapshot) { method in
                    viewModel.unlockHint(for: snapshot, method: method)
                    pendingSnapshot = nil
                    showHintPaywall = false
                } onCancel: {
                    pendingSnapshot = nil
                    showHintPaywall = false
                }
                .environmentObject(gameState)
            }
        }
    }
}

private extension CaseSessionView {
    private func shouldShowHintBanner(for snapshot: CaseSnapshot) -> Bool {
        switch snapshot.status {
        case .solved, .failed:
            return !viewModel.hints.isEmpty
        default:
            return true
        }
    }

    private func isCaseClosed(_ snapshot: CaseSnapshot) -> Bool {
        switch snapshot.status {
        case .solved, .failed:
            return true
        default:
            return false
        }
    }
}

private struct CaseHeaderView: View {
    let snapshot: CaseSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(snapshot.title)
                .font(.title2.weight(.semibold))
            Text(snapshot.synopsis)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            CaseStatusBadge(status: snapshot.status)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct CaseStatusBadge: View {
    let status: CaseStatus

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }

    private var label: String {
        switch status {
        case .briefing:
            return "Briefing"
        case .investigation:
            return "Soruşturma"
        case .solved:
            return "Çözüldü"
        case .failed:
            return "Çözülemedi"
        }
    }

    private var background: Color {
        switch status {
        case .briefing:
            return .gray
        case .investigation:
            return .blue
        case .solved:
            return .green
        case .failed:
            return .red
        }
    }
}

private struct SuspectsSection: View {
    let suspects: [SuspectProfile]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Şüpheliler")
                .font(.headline)
            ForEach(suspects) { suspect in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(suspect.name)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(suspect.trust.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.secondarySystemFill))
                            .clipShape(Capsule())
                    }
                    Text(suspect.occupation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Motive: \(suspect.motive)")
                        .font(.caption)
                    Text("Alibi: \(suspect.alibi)")
                        .font(.caption)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CluesSection: View {
    let clues: [Clue]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("İpuçları")
                .font(.headline)
            if clues.isEmpty {
                Text("Henüz ipucu yok.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(clues) { clue in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(clue.title)
                            .font(.subheadline.weight(.semibold))
                        Text(clue.detail)
                            .font(.caption)
                        Text(clue.category.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HintsSection: View {
    let hints: [CaseHint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("İpucu Defteri")
                .font(.headline)
            if hints.isEmpty {
                Text("Henüz ipucu açılmadı. İpucu almak için üstteki paneli kullan.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(hints) { hint in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(hint.text)
                            .font(.body)
                        Text(methodLabel(for: hint.method))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func methodLabel(for method: HintUnlockMethod) -> String {
        switch method {
        case .dailyAllowance:
            return "Günlük ücretsiz hak"
        case .hintCredit:
            return "İpucu kredisi"
        case .energy:
            return "Enerji karşılığı"
        case .rewarded:
            return "Reklam ödülü"
        case .subscription:
            return "Detective Plus"
        }
    }
}

private struct ConversationSection: View {
    let turns: [CaseTurn]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Soruşturma Akışı")
                .font(.headline)
            ForEach(turns) { turn in
                HStack(alignment: .top) {
                    if turn.speaker == .engine {
                        bubble(for: turn, alignment: .leading)
                        Spacer(minLength: 48)
                    } else {
                        Spacer(minLength: 48)
                        bubble(for: turn, alignment: .trailing)
                    }
                }
            }
        }
    }

    private func bubble(for turn: CaseTurn, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(turn.text)
                .font(.body)
                .foregroundColor(turn.speaker == .engine ? Color.primary : Color.white)
            if !turn.newClues.isEmpty {
                Divider()
                Text("Yeni ipuçları:")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(turn.speaker == .engine ? Color.secondary : Color.white.opacity(0.8))
                ForEach(turn.newClues) { clue in
                    Text(clue.title)
                        .font(.caption)
                        .foregroundColor(turn.speaker == .engine ? Color.secondary : Color.white.opacity(0.8))
                }
            }
        }
        .padding(12)
        .background(turn.speaker == .engine ? Color(.systemBackground) : Color.accentColor)
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

private struct InputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Sorunu yaz...", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
            if isLoading {
                ProgressView()
            }
            Button(action: onSubmit) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18, weight: .semibold))
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
    }
}

private struct HintBanner: View {
    let hints: [CaseHint]
    let hasDetectivePlus: Bool
    let isCaseClosed: Bool
    let requestHint: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("İpucu Merkezi")
                .font(.headline)
            if hasDetectivePlus {
                Text("Detective Plus sayesinde sınırsız ipucunuz var. İhtiyaç duyduğunda açmaya devam edebilirsin.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if isCaseClosed {
                Text("Vaka kapandı; yeni ipucu açmak mümkün değil. Açtığın ipuçlarını aşağıdan inceleyebilirsin.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Takıldığın yerde yeni ipuçları açarak ilerlemeyi hızlandırabilirsin. İlk ipucu genellikle son bulunan kanıt üzerinde yoğunlaşır.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !hints.isEmpty {
                Text("Açılmış ipucu sayısı: \(hints.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button(action: requestHint) {
                Label(hints.isEmpty ? "İpucu aç" : "Yeni ipucu aç", systemImage: "lightbulb")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCaseClosed)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct HintPaywallView: View {
    let snapshot: CaseSnapshot
    let onUnlock: (HintUnlockMethod) -> Void
    let onCancel: () -> Void

    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var isRewarding = false
    @State private var infoMessage: String?
    @State private var didAutoUnlock = false

    private let hintEnergyCost = 1

    var body: some View {
        NavigationStack {
            List {
                Section("Vaka Özeti") {
                    Text(snapshot.title)
                        .font(.subheadline.weight(.semibold))
                    Text(snapshot.synopsis)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Mevcut ipuçları: \(snapshot.clues.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !gameState.hasDetectivePlus {
                    purchaseSection
                } else {
                    Section("Detective Plus") {
                        Text("Aboneliğin aktif. İpucu otomatik açılıyor.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .task { autoUnlock(method: .subscription) }
                    }
                }

                if let infoMessage {
                    Section {
                        Text(infoMessage)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("İpucu Aç")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        onCancel()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var purchaseSection: some View {
        Section("İpucu Seçenekleri") {
            if gameState.hintCredits > 0 {
                Button {
                    if gameState.consumeHintCredit() {
                        completeUnlock(method: .hintCredit)
                    } else {
                        infoMessage = "İpucu kredin kalmadı. Reklam izleyebilir veya enerji kullanabilirsin."
                    }
                } label: {
                    Label("İpucu kredisi kullan (\(gameState.hintCredits))", systemImage: "lightbulb.fill")
                }
            }

            Button {
                if gameState.consumeEnergy(points: hintEnergyCost) {
                    completeUnlock(method: .energy)
                } else {
                    infoMessage = "Yeterli enerjin yok. Enerji mağazasından takviye alabilirsin."
                }
            } label: {
                Label("\(hintEnergyCost) enerji karşılığı aç", systemImage: "bolt")
            }

            Button {
                triggerRewarded()
            } label: {
                HStack {
                    Label("Reklam izle ve ipucu aç", systemImage: "play.rectangle")
                    Spacer()
                    if isRewarding {
                        ProgressView()
                    }
                }
            }
            .disabled(isRewarding)

            Button {
                gameState.activateDetectivePlus()
                infoMessage = "Detective Plus etkinleştirildi. İpucu otomatik açılıyor."
                autoUnlock(method: .subscription)
            } label: {
                Label("Detective Plus aboneliğini simüle et", systemImage: "infinity")
            }
        }
    }

    private func completeUnlock(method: HintUnlockMethod) {
        infoMessage = nil
        onUnlock(method)
        didAutoUnlock = true
        dismiss()
    }

    private func autoUnlock(method: HintUnlockMethod) {
        guard !didAutoUnlock else { return }
        didAutoUnlock = true
        DispatchQueue.main.async {
            onUnlock(method)
            dismiss()
        }
    }

    private func triggerRewarded() {
        guard !isRewarding else { return }
        isRewarding = true
        infoMessage = "Reklam oynatılıyor..."
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                infoMessage = "Reklam tamamlandı. İpucu açılıyor."
                isRewarding = false
                completeUnlock(method: .rewarded)
            }
        }
    }
}

// Compatibility helper for iOS 16 and iOS 17+ onChange overloads
private extension View {
    @ViewBuilder
    func onChangeCompat<Value: Equatable>(of value: Value, action: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) {
                action()
            }
        } else {
            self.onChange(of: value) { _ in
                action()
            }
        }
    }
}

#Preview {
    NavigationStack {
        CaseSessionView(viewModel: CaseSessionViewModel(caseType: .homicide))
            .environmentObject(GameState(initialMaxEnergy: 10, dailyEnergyAllowance: 3))
    }
}
