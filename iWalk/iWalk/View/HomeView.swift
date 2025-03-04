//
//  HomeView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    
    @Query private var meals: [Meal]
    
    private var kcal: Int {
        meals.reduce(0) { $0 + $1.kcal }
    }
    
    @AppStorage("targetCalories") private var target = 1000
    
    private let healthData = HealthData()
    
    @State private var steps = 0
    
    @State private var showPicker = false
    
    private var kcalsToBurn: Int {
        kcal - target > 0 ? kcal - target : 0
    }
    
    
    var attributedString: AttributedString {
        var string = AttributedString("Questa è una frase con parola colorata alla fine.")
        if let range = string.range(of: "parola colorata") {
            string[range].foregroundColor = .red
        }
        return string
    }
    
    
    
    @State private var stepsToDo = 0
    
    
    
    
    var body: some View {
        GeometryReader { screen in
            NavigationStack {
                ZStack {
                    LavaLampView(frame: screen.size, blobs: 10)
                    
                    ScrollView(.vertical) {
                        ZStack {
                            
                            Spacer().containerRelativeFrame([.horizontal, .vertical])
                            
                            VStack(spacing: 50) {
                                
                                Text("Oggi hai assunto \(kcal) kcal")
                                
                                Text("e hai fatto \(steps) passi")
                                
                                Button {
                                    withAnimation {
                                        showPicker.toggle()
                                    }
                                } label: {
                                    HStack {
                                        Text("Obiettivo:")
                                            .foregroundStyle(Color.primary)
                                        Text("\(target) kcal")
                                            .blurredBackgorund()
                                        Image(systemName: "chevron.up")
                                            .blurredBackgorund()
                                            .rotationEffect(.degrees(showPicker ? 180 : 0))
                                    }
                                }
                                
                                if showPicker {
                                    Picker("Seleziona kcal", selection: $target) {
                                        ForEach(Array(stride(from: 1000, through: 3000, by: 200)), id: \.self) { value in
                                            Text("\(value) kcal")
                                                .font(.title)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 150)
                                    .transition(.opacity)
                                    .onChange(of: target) {
                                        withAnimation {
                                            updateData()
                                        }
                                        
                                    }
                                }
                                
                                if(kcalsToBurn == 0) {
                                    Text("Obiettivo raggiunto!")
                                        .foregroundStyle(.tint)
                                        .blurredBackgorund()
                                } else {
                                    Text("Devi fare ancora \(stepsToDo) passi per bruciare \(kcalsToBurn) kcal")
                                }
                                
                                
                            }
                            .font(.title)
                            .bold()
                            .padding()
                            
                        }
                        
                        
                    }
                    .customNSToolbar(title: "iWalk") {
                        Image(systemName: "figure.walk")
                            .blurredBackgorund()
                    }
                    .onAppear {
                        updateData()
                    }
                    .refreshable {
                        withAnimation {
                            updateData()
                        }
                    }
                }
            }
        }
        
        
        
    }
    
    
    
    func updateData() {
        do {
            stepsToDo = try healthData.predictSteps(forCalories: kcalsToBurn)
        } catch {
            
        }
        Task {
            do {
                let tempSteps = try await healthData.fetchTodaySteps()
                
                DispatchQueue.main.async {
                    steps = tempSteps
                }
            } catch {
                
            }
        }
        
        stepsToDo -= steps
    }
    
}

#Preview {
    HomeView()
}
