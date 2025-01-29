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
        ZStack {
            Image(systemName: "gear")
                .resizable()
                .scaledToFit()
                .opacity(0.1)
            
            VStack {
                List {
                    ForEach(0...10, id: \.self) { index in
                        Text("Hello \(index)")
                    }
                    
                    Button {
                        x += 1
                    } label: {
                        Text("Hello")
                    }
                }
                
                Button {
                    x += 1
                } label: {
                    Text("Hello")
                }
            }
        }
    }
    
    
}

#Preview {
    SettingsView()
}
