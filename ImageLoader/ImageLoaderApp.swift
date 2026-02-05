//
//  ImageLoaderApp.swift
//  ImageLoader
//
//  Created by Digvijay Tyagi on 14/11/25.
//

import SwiftUI
import SwiftData

@main
struct ImageLoaderApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                //For now added the cleanup cache call when app foregrounds. Will revisit this
                DiskCache().cleanupDiskCache()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
