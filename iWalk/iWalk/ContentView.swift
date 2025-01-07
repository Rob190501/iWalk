//
//  ContentView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView()
            }
            
            Tab("Food", systemImage: "carrot") {
                FoodView()
            }
            
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
            
            Tab("Test", systemImage: "warninglight") {
                HealthDataView()
            }
        }
    }
}

#Preview {
    ContentView()
}
