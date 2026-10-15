//
//  PCMNotesApp.swift
//  PCMNotes
//
//  Created by Apoorv Darshan on 20/07/26.
//

import SwiftUI

@main
struct PCMNotesApp: App {
    @StateObject private var tipStore: TipStore

    init() {
        let purchaser = Self.makeTipPurchaser()
        _tipStore = StateObject(wrappedValue: TipStore(purchaser: purchaser))
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

    /// RevenueCat for every real launch; a local tip store only for Debug
    /// Simulator test launches (see TestEnvironment).
    private static func makeTipPurchaser() -> any TipPurchasing {
        #if DEBUG
        if let testPurchaser = TestEnvironment.tipPurchaser() {
            return testPurchaser
        }
        #endif
        RevenueCatConfiguration.configure()
        return RevenueCatTipPurchasing()
    }
}
