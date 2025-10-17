//
//  CaseSessionView.swift
//  Unknown Detective
//
//  Rewritten to fix compile errors and provide a clean SwiftUI implementation.

import SwiftUI
import Foundation

struct CaseSessionView: View {
    @StateObject var viewModel: CaseSessionViewModel
    @EnvironmentObject private var gameState: GameState

    @State private var showHintSheet = false
    @State private var hintEnergyCost = 2

    init(viewModel: CaseSessionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [NoirTheme.backgroundTop, NoirTheme.backgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            content
        }
        .toolbar { toolbarContent }
        .sheet(isPresented: $showHintSheet) {
            if let snapshot = viewModel.snapshot {
                HintPaywallView(
                    hintEnergyCost: hintEnergyCost,
                    onUnlock: { method in
                        viewModel.unlockHint(for: snapshot, method: method)
                    }
                )
                .environmentObject(gameState)
            }
        }
        .onAppear { viewModel.start() }
        .navigationTitle("Vaka")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = viewModel.snapshot {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CaseHeaderView(snapshot: snapshot)

                    if shouldShowHintBanner(for: snapshot) {
                        HintBanner(
                            hints: viewModel.hints,
                            hasDetectivePlus: gameState.hasDetectivePlus,
                            isCaseClosed: isCaseClosed(snapshot),
                            requestHint: requestHint
                        )
                    }

                    ConversationSection(turns: snapshot.turns)
                        .padding(.horizontal, 16)

                    SuspectsSection(suspects: snapshot.suspects)
                        .padding(.horizontal, 16)

                    CluesSection(clues: snapshot.clues)
                        .padding(.horizontal, 16)

                    HintsSection(hints: viewModel.hints)
                        .padding(.horizontal, 16)

                    Spacer(minLength: 100)
                }
                .padding(.top, 16)
            }
            .safeAreaInset(edge: .bottom) {
                InputBar(text: $viewModel.inputText, isLoading: viewModel.isLoading) {
                    viewModel.sendQuestion()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        } else {
            VStack(spacing: 12) {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                } else {
                    ProgressView("Vaka yükleniyor…")
                        .tint(.white)
                }
            }
            .padding()
        }
    }

    private func requestHint() {
        if gameState.hasDetectivePlus, let snapshot = viewModel.snapshot {
            viewModel.unlockHint(for: snapshot, method: .subscription)
        } else {
            showHintSheet = true
        }
    }

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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.isLoading {
                ProgressView().tint(.white)
            }
        }
    }
}

private struct CaseHeaderView: View {
    let snapshot: CaseSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(snapshot.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(snapshot.synopsis)
                .font(.subheadline)
                .foregroundStyle(NoirTheme.subtleText)
            CaseStatusBadge(status: snapshot.status)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [NoirTheme.cardBackground.opacity(0.95), NoirTheme.cardBackground.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(NoirTheme.accent.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: NoirTheme.accent.opacity(0.12), radius: 12, x: 0, y: 8)
        .padding(.horizontal, 16)
    }
}

private struct CaseStatusBadge: View {
    let status: CaseStatus

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
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
            return NoirTheme.subtleText.opacity(0.6)
        case .investigation:
            return NoirTheme.neon
        case .solved:
            return NoirTheme.success
        case .failed:
            return NoirTheme.caution
        }
    }
}

private struct SuspectsSection: View {
    let suspects: [SuspectProfile]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Şüpheliler", systemImage: "person.2.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }
            ForEach(suspects) { suspect in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(suspect.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
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
                        .foregroundStyle(NoirTheme.subtleText)
                    Text("Motive: \(suspect.motive)")
                        .font(.caption)
                        .foregroundStyle(.white)
                    Text("Alibi: \(suspect.alibi)")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
                .padding(16)
                .background(NoirTheme.cardBackground.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(NoirTheme.accent.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CluesSection: View {
    let clues: [Clue]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("İpuçları", systemImage: "magnifyingglass")
                .font(.headline)
                .foregroundStyle(.white)
            if clues.isEmpty {
                Text("Henüz ipucu yok.")
                    .font(.caption)
                    .foregroundStyle(NoirTheme.subtleText)
            } else {
                ForEach(clues) { clue in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(clue.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(clue.detail)
                            .font(.caption)
                            .foregroundStyle(.white)
                        Text(clue.category.rawValue)
                            .font(.caption2)
                            .foregroundStyle(NoirTheme.subtleText)
                    }
                    .padding(16)
                    .background(NoirTheme.cardBackground.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(NoirTheme.accent.opacity(0.15), lineWidth: 1)
                    )
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
            Label("İpucu Defteri", systemImage: "lightbulb")
                .font(.headline)
                .foregroundStyle(.white)
            if hints.isEmpty {
                Text("Henüz ipucu açılmadı. İpucu almak için üstteki paneli kullan.")
                    .font(.caption)
                    .foregroundStyle(NoirTheme.subtleText)
            } else {
                ForEach(hints) { hint in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(hint.text)
                            .font(.body)
                            .foregroundStyle(.white)
                        Text(methodLabel(for: hint.method))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(18)
                    .background(NoirTheme.cardBackground.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(NoirTheme.accent.opacity(0.2), lineWidth: 1)
                    )
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
            Label("Soruşturma Akışı", systemImage: "waveform")
                .font(.headline)
                .foregroundStyle(NoirTheme.subtleText)
            ForEach(turns) { turn in
                HStack(alignment: .top) {
                    if turn.speaker == .engine {
                        bubble(for: turn, isEngine: true)
                        Spacer(minLength: 48)
                    } else {
                        Spacer(minLength: 48)
                        bubble(for: turn, isEngine: false)
                    }
                }
            }
        }
    }

    private func bubble(for turn: CaseTurn, isEngine: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(turn.text)
                .font(.body)
                .foregroundStyle(isEngine ? .white : NoirTheme.backgroundTop)
            if !turn.newClues.isEmpty {
                Divider()
                    .background(Color.white.opacity(isEngine ? 0.15 : 0.3))
                Text("Yeni ipuçları:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isEngine ? NoirTheme.subtleText : NoirTheme.backgroundTop.opacity(0.8))
                ForEach(turn.newClues) { clue in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(clue.title)
                            .font(.caption)
                            .foregroundStyle(isEngine ? .white.opacity(0.9) : NoirTheme.backgroundTop.opacity(0.9))
                        Text(clue.detail)
                            .font(.caption2)
                            .foregroundStyle(isEngine ? NoirTheme.subtleText : NoirTheme.backgroundTop.opacity(0.75))
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: isEngine ? .leading : .trailing)
        .background(
            ZStack {
                if isEngine {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(NoirTheme.cardBackground.opacity(0.9))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [NoirTheme.accent, NoirTheme.neon], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(isEngine ? 0.06 : 0.12), lineWidth: 1)
        )
        .shadow(color: NoirTheme.accent.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

private struct InputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSubmit: () -> Void

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        let isSendDisabled = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading

        HStack(alignment: .bottom, spacing: 12) {
            TextField("Sorgunu yaz...", text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(NoirTheme.backgroundTop.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(Color.white)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.sentences)
                .focused($isFieldFocused)
                .submitLabel(.send)
                .onSubmit(sendIfPossible)

            Button(action: sendIfPossible) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.white)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.white)
                }
            }
            .frame(width: 48, height: 48)
            .background(isSendDisabled ? NoirTheme.cardBackground.opacity(0.7) : NoirTheme.accent)
            .clipShape(Circle())
            .shadow(color: NoirTheme.accent.opacity(isSendDisabled ? 0.08 : 0.25), radius: 8, x: 0, y: 4)
            .disabled(isSendDisabled)
        }
        .onAppear { isFieldFocused = true }
    }

    private func sendIfPossible() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading else { return }
        text = trimmed
        onSubmit()
    }
}

private struct HintBanner: View {
    let hints: [CaseHint]
    let hasDetectivePlus: Bool
    let isCaseClosed: Bool
    let requestHint: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("İpucu Merkezi", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundStyle(Color.white)
                Spacer()
                if !isCaseClosed {
                    Button(action: requestHint) {
                        Text(hints.isEmpty ? "İpucu aç" : "Yeni ipucu")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(NoirTheme.accent)
                            .clipShape(Capsule())
                            .foregroundStyle(Color.white)
                    }
                    .buttonStyle(.plain)
                }
            }

            bannerMessage

            if !hints.isEmpty {
                Text("Açılmış ipucu sayısı: \(hints.count)")
                    .font(.caption)
                    .foregroundStyle(NoirTheme.subtleText)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(NoirTheme.cardBackground.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(NoirTheme.accent.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: NoirTheme.accent.opacity(0.16), radius: 10, x: 0, y: 6)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var bannerMessage: some View {
        if hasDetectivePlus {
            Text("Detective Plus aktif: İhtiyaç duyduğunda ipuçları anında açılıyor.")
                .font(.caption)
                .foregroundStyle(NoirTheme.subtleText)
        } else if isCaseClosed {
            Text("Vaka kapandı; açılan ipuçlarını inceleyebilirsin fakat yenisi eklenmeyecek.")
                .font(.caption)
                .foregroundStyle(NoirTheme.subtleText)
        } else {
            Text("Takıldığında ipuçlarından yararlan. İlk ipucu genellikle son kanıtı detaylandırır.")
                .font(.caption)
                .foregroundStyle(NoirTheme.subtleText)
        }
    }
}

private struct HintPaywallView: View {
    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    let hintEnergyCost: Int
    let onUnlock: (HintUnlockMethod) -> Void

    @State private var isRewarding = false
    @State private var infoMessage: String?
    @State private var didAutoUnlock = false

    var body: some View {
        NavigationStack {
            List {
                if let infoMessage {
                    Section {
                        Text(infoMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("İpucu Seçenekleri") {
                    if gameState.hasDetectivePlus {
                        Button {
                            autoUnlock(method: .subscription)
                        } label: {
                            Label("Detective Plus ile ücretsiz aç", systemImage: "infinity")
                        }
                    }

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
                                    .tint(NoirTheme.accent)
                            }
                        }
                    }
                    .disabled(isRewarding)
                }
            }
            .navigationTitle("İpucu Aç")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            if gameState.hasDetectivePlus { autoUnlock(method: .subscription) }
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

#Preview {
    NavigationStack {
        CaseSessionView(viewModel: CaseSessionViewModel(caseType: .homicide))
            .environmentObject(GameState(initialMaxEnergy: 10, dailyEnergyAllowance: 3))
    }
}
