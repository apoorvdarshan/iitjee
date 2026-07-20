//
//  iitjeeApp.swift
//  iitjee
//
//  Created by Apoorv Darshan on 20/07/26.
//

import RevenueCat
import SwiftUI

@main
struct iitjeeApp: App {
    @StateObject private var tipStore: TipStore

    init() {
        RevenueCatConfiguration.configure()
        _tipStore = StateObject(wrappedValue: TipStore())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tipStore)
                .task {
                    await tipStore.start()
                }
        }
    }
}
