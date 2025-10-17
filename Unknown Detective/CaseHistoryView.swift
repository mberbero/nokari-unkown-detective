//
//  CaseHistoryView.swift
//  Unknown Detective
//
//  View for browsing and managing case history logs.
//

import SwiftUI

struct CaseHistoryView: View {
    @EnvironmentObject var history: CaseHistoryStore
    @Environment(\.dismiss) private var dismiss
    let onStartCase: ((CaseType) -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if history.logs.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(history.logs) { log in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(statusColor(for: log))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: icon(for: log.type))
                                            .foregroundStyle(.white)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(log.title)
                                        .font(.subheadline.weight(.semibold))

                                    HStack(spacing: 6) {
                                        Text(log.type.rawValue)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)

                                        Text("•").font(.caption2).foregroundStyle(.secondary)

                                        Text(log.status)
                                            .font(.caption2)
                                            .foregroundStyle(statusColor(for: log))
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(log.date, style: .date)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Text("Dönüş: \(log.turns)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onStartCase?(log.type)
                                dismiss()
                            }
                        }
                        .onDelete(perform: history.remove)
                    }
                    .scrollContentBackground(.hidden)
                    .background(background)
                }
            }
            .navigationTitle("Geçmiş")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Tümünü Sil", role: .destructive) { history.removeAll() }
                        .disabled(history.logs.isEmpty)
                }
            }
        }
        .tint(NoirTheme.accent)
        .preferredColorScheme(.dark)
        .onAppear { Haptics.light() }
    }

    private var background: some View {
        LinearGradient(colors: [NoirTheme.backgroundTop, NoirTheme.backgroundBottom], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }

    private func icon(for type: CaseType) -> String {
        switch type {
        case .homicide: return "drop.triangle"
        case .missingPerson: return "person.fill.questionmark"
        case .heist: return "banknote"
        }
    }

    private func statusColor(for log: CaseLog) -> Color {
        log.status.contains("Çözüldü") ? NoirTheme.success : NoirTheme.caution
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.largeTitle)
                .foregroundStyle(NoirTheme.subtleText)

            Text("Henüz kapanmış vaka yok.")
                .foregroundStyle(NoirTheme.subtleText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
    }
}

#Preview {
    let store = CaseHistoryStore()
    return CaseHistoryView(onStartCase: { _ in }).environmentObject(store)
}
