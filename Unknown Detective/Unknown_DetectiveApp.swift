//
//  Unknown_DetectiveApp.swift
//  Unknown Detective
//
//  Created by Mansur Berbero on 17.10.2025.
//

import SwiftUI
import CoreData

@main
struct Unknown_DetectiveApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("hasSeenSplash") private var hasSeenSplash = false
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                if !hasSeenSplash && showSplash {
                    SplashView {
                        hasSeenSplash = true
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .onAppear {
                // If splash was shown before, skip it
                if hasSeenSplash { showSplash = false }
            }
        }
    }
}
