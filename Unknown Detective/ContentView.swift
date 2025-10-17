//
//  ContentView.swift
//  Unknown Detective
//
//  Created by Mansur Berbero on 17.10.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var path: [CaseType] = []

    var body: some View {
        NavigationStack(path: $path) {
            CaseSelectionView { caseType in
                path.append(caseType)
            }
            .navigationTitle("Unknown Detective")
            .navigationDestination(for: CaseType.self) { caseType in
                CaseSessionView(viewModel: CaseSessionViewModel(caseType: caseType))
            }
        }
    }
}

struct CaseSelectionView: View {
    let startCase: (CaseType) -> Void

    var body: some View {
        List {
            Section("Yeni Vaka") {
                ForEach(CaseType.allCases) { caseType in
                    Button {
                        startCase(caseType)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: icon(for: caseType))
                                .foregroundStyle(.accent)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(caseType.rawValue)
                                    .font(.headline)
                                Text(caseType.tagline)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func icon(for caseType: CaseType) -> String {
        switch caseType {
        case .homicide:
            return "drop.triangle"
        case .missingPerson:
            return "person.fill.questionmark"
        case .heist:
            return "banknote"
        }
    }
}

#Preview {
    ContentView()
}
