//
//  ContentView.swift
//  iitjee
//
//  Created by Apoorv Darshan on 20/07/26.
//

import SwiftUI

private enum AppTab: Hashable {
    case physics
    case chemistry
    case mathematics
    case support
    case about

    var accent: Color {
        switch self {
        case .physics: AppPalette.physics
        case .chemistry: AppPalette.chemistry
        case .mathematics: AppPalette.mathematics
        case .support: AppPalette.support
        case .about: AppPalette.about
        }
    }
}

struct ContentView: View {
    @State private var selection: AppTab = .physics

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                SubjectView(subject: .physics)
            }
            .tabItem {
                Label("Physics", systemImage: "atom")
            }
            .tag(AppTab.physics)

            NavigationStack {
                SubjectView(subject: .chemistry)
            }
            .tabItem {
                Label("Chemistry", systemImage: "flask.fill")
            }
            .tag(AppTab.chemistry)

            NavigationStack {
                SubjectView(subject: .mathematics)
            }
            .tabItem {
                Label("Maths", systemImage: "function")
            }
            .tag(AppTab.mathematics)

            NavigationStack {
                SupportView()
            }
            .tabItem {
                Label("Support", systemImage: "questionmark.circle.fill")
            }
            .tag(AppTab.support)

            NavigationStack {
                AboutView()
            }
            .tabItem {
                Label("About", systemImage: "info.circle.fill")
            }
            .tag(AppTab.about)
        }
        .tint(selection.accent)
        .nativeTabMinimization()
    }
}

#Preview {
    ContentView()
}
