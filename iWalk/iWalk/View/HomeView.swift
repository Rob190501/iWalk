//
//  HomeView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    
    private let healthService = HealthService.shared
    
    private let stepsPredictor = StepsPredictor.shared
    
    @Query private var meals: [Meal]
    
    @State private var todaySteps = 0
    
    @State private var stepsToDo = 0
    
    @AppStorage("targetKcals") private var target = 1000
    
    @State private var showingAlert = false
    
    @State private var alertMessage = ""
    
    private var todayKcals: Int {
        meals.reduce(0) { $0 + $1.kcal }
    }
    
    private var kcalsToBurn: Int {
        todayKcals - target > 0 ? todayKcals - target : 0
    }
    
    
    
    var body: some View {
        GeometryReader { screen in
            NavigationStack {
                ZStack {
                    LavaLampView(frame: screen.size, blobs: 10)
                    
                    ScrollView(.vertical) {
                        ZStack {
                            
                            Spacer().containerRelativeFrame([.horizontal, .vertical])
                            
                            VStack(spacing: 70) {
                                TodayDataView(kcal: todayKcals, steps: todaySteps)
                                
                                TargetPickerView(target: $target, updateData: updateData)
                                
                                TargetView(kcalsToBurn: kcalsToBurn, stepsToDo: stepsToDo)
                            }
                            .font(.title)
                            .bold()
                            .padding()
                            .onAppear {
                                updateData()
                            }
                        }
                    }
                    .refreshable {
                        withAnimation {
                            updateData()
                        }
                    }
                }
                .customNSToolbar(title: "iWalk") {
                    Image(systemName: "figure.walk")
                        .blurredBackgorund()
                }
            }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("Ok", role: .cancel) { }
            }
        }
    }
    
    
    
    func updateData() {
        Task {
            do {
                let tempStepsToDo = try await stepsPredictor.predictSteps(forCalories: kcalsToBurn)
                let tempTodaySteps = try await healthService.fetchTodaySteps()
                
                DispatchQueue.main.async {
                    todaySteps = tempTodaySteps
                    stepsToDo = tempStepsToDo - todaySteps
                }
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
    
    
    
    struct TodayDataView: View {
        var kcal: Int
        var steps: Int
        
        var body: some View {
            VStack(spacing: 20) {
                HStack {
                    Text("Oggi hai assunto ")
                    Text("\(kcal) kcal")
                        .blurredBackgorund()
                }
                
                HStack {
                    Text("e hai fatto ")
                    Text("\(steps) passi")
                        .blurredBackgorund()
                }
            }
        }
    }
    
    struct TargetPickerView: View {
        @Binding var target: Int
        @State private var showPicker = false
        var updateData: () -> Void
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Apporto energetico desiderato:")
                    .multilineTextAlignment(.center)
                Button {
                    withAnimation {
                        showPicker.toggle()
                    }
                } label: {
                    HStack {
                        Text("\(target) kcal")
                            
                        Image(systemName: "chevron.up")
                            .rotationEffect(.degrees(showPicker ? 180 : 0))
                    }
                    .blurredBackgorund()
                }
                
                if showPicker {
                    Picker("Seleziona kcal", selection: $target) {
                        ForEach(Array(stride(from: 1000, through: 3000, by: 100)), id: \.self) { value in
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
                
            }
        }
        
    }
    
    struct TargetView: View {
        var kcalsToBurn: Int
        var stepsToDo: Int
        
        var body: some View {
            if kcalsToBurn == 0 || stepsToDo < 1 {
                Text("Obiettivo raggiunto!")
                    .blurredBackgorund()
            } else {
                VStack(spacing: 20) {
                    HStack {
                        Text("Devi fare ancora ")
                        Text("\(stepsToDo) passi")
                            .blurredBackgorund()
                    }
                    
                    HStack {
                        Text("per bruciare")
                        Text("\(kcalsToBurn) kcal")
                            .blurredBackgorund()
                    }
                }
            }
        }
    }
    
}

#Preview {
    HomeView()
}
