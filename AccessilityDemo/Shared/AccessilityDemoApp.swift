//
//  AccessilityDemoApp.swift
//  Shared
//
//  Created by Erwan BOUET on 12/03/2022.
//

import SwiftUI

@main
struct AccessilityDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: .init())
                .environment(\.managedObjectContext, DiseasesProvider.container.viewContext)
        }
    }
}
