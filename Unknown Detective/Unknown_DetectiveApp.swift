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
    @State private var showSplash = !UserDefaults.standard.bool(forKey: "hasShownSplash")

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                if showSplash {
                    SplashView {
                        UserDefaults.standard.set(true, forKey: "hasShownSplash")
                        showSplash = false
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}
