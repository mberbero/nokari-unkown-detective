//
//  CaseSessionView.swift
//  Unknown Detective
//
//  Created by GitHub Copilot on 17.10.2025.
//

import SwiftUI

struct CaseSessionView: View {
    @ObservedObject var viewModel: CaseSessionViewModel
    private let bottomID = "conversationBottom"

    var body: some View {
        VStack(spacing: 0) {
            if let snapshot = viewModel.snapshot {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            CaseHeaderView(snapshot: snapshot)
                            SuspectsSection(suspects: snapshot.suspects)
                            CluesSection(clues: snapshot.clues)
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
                    .onChange(of: snapshot.turns.last?.id) { _ in
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

private struct ConversationSection: View {
    let turns: [CaseTurn]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Soruşturma Akışı")
                .font(.headline)
            ForEach(turns) { turn in
                HStack {
                    if turn.speaker == .engine {
                        bubble(for: turn)
                        Spacer(minLength: 48)
                    } else {
                        Spacer(minLength: 48)
                        bubble(for: turn)
                    }
                }
            }
        }
    }

    private func bubble(for turn: CaseTurn) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(turn.text)
                .font(.body)
                .foregroundStyle(turn.speaker == .engine ? .primary : .white)
            if !turn.newClues.isEmpty {
                Divider()
                Text("Yeni ipuçları:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(turn.speaker == .engine ? .secondary : .white.opacity(0.8))
                ForEach(turn.newClues) { clue in
                    Text(clue.title)
                        .font(.caption)
                        .foregroundStyle(turn.speaker == .engine ? .secondary : .white.opacity(0.8))
                }
            }
        }
        .padding(12)
        .background(turn.speaker == .engine ? Color(.systemBackground) : Color.accentColor)
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

#Preview {
    NavigationStack {
        CaseSessionView(viewModel: CaseSessionViewModel(caseType: .homicide))
    }
}
