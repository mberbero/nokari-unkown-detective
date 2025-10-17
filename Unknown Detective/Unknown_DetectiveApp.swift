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
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                if showSplash {
                    SplashView {
                        showSplash = false
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}
