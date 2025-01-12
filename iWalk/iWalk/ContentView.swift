//
//  ContentView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: 0) {
                HomeView()
            }
            
            Tab("Pasti", systemImage: "carrot", value: 1) {
                MealView()
            }
            
            Tab("Impostazioni", systemImage: "gear", value: 2) {
                SettingsView()
            }
            
            Tab("Test", systemImage: "warninglight", value: 3) {
                HealthDataView()
            }
        }
        .tint({
            switch selectedTab {
            case 1:
                return Color.orange
            default:
                return Color.accentColor
            }
        }())
    }
}

#Preview {
    ContentView()
}
