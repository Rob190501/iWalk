//
//  SettingsView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var x = 0
    
    var body: some View {
        NavigationStack {
            List {
                SettingsRow(icon: "gearshape.fill", color: .gray, title: "Generali", destination: Text("Hello"))
                SettingsRow(icon: "gearshape.fill", color: .gray, title: "Generali", destination: Text("Hello"))
                SettingsRow(icon: "gearshape.fill", color: .gray, title: "Generali", destination: Text("Hello"))
            }
            .customToolbar(icon: "gear", title: "Impostazioni")
        }
    }
}



struct SettingsRow<Destination: View>: View {
    let icon: String
    let color: Color
    let title: String
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .padding(6)
                    .background(color)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text(title)
                    .font(.body)
                    
            }
        }
    }
}



#Preview {
    SettingsView()
}
