//
//  iWalkApp.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//

import SwiftUI
import SwiftData

@main
struct iWalkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Meal.self)
        }
    }
}
