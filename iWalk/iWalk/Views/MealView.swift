//
//  MealView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//

import SwiftUI
import SwiftData


struct MealView: View {
    @Query private var meals: [Meal]
    
    private let sampleBreakfast = Meal(mealTime: .breakfast, details: "", kcal: 0)
    
    private let sampleMorningSnack = Meal(mealTime: .morningSnack, details: "", kcal: 0)
    
    private let sampleLunch = Meal(mealTime: .lunch, details: "", kcal: 0)
    
    private let sampleAfternoonSnack = Meal(mealTime: .afternoonSnack, details: "", kcal: 0)
    
    private let sampleDinner = Meal(mealTime: .dinner, details: "", kcal: 0)
    
    @StateObject private var gpt = GPT()
    
    var body: some View {
        
        NavigationStack {
            ScrollView {
                Spacer()
                
                MealField(label: "Colazione",
                          meal: meals.filter { $0.mealTime == MealTime.breakfast.rawValue }.first ?? sampleBreakfast,
                          gpt: gpt)
                
                CustomDivider()
                
                MealField(label: "Snack mattutino",
                          meal: meals.filter { $0.mealTime == MealTime.morningSnack.rawValue }.first ?? sampleMorningSnack,
                          gpt: gpt)
                
                CustomDivider()
                
                MealField(label: "Pranzo",
                          meal: meals.filter { $0.mealTime == MealTime.lunch.rawValue }.first ?? sampleLunch,
                          gpt: gpt)
                
                CustomDivider()
                
                MealField(label: "Snack pomeridiano",
                          meal: meals.filter { $0.mealTime == MealTime.afternoonSnack.rawValue }.first ?? sampleAfternoonSnack,
                          gpt: gpt)
                
                CustomDivider()
                
                MealField(label: "Cena",
                          meal: meals.filter { $0.mealTime == MealTime.dinner.rawValue }.last ?? sampleDinner,
                          gpt: gpt)
            }
            .padding(.horizontal)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "carrot")
                            .foregroundStyle(.tint)
                            .font(.title)
                            .bold()
                        Text("Pasti")
                            .font(.largeTitle)
                            .bold()
                        Spacer()
                        Text("Totale: \(meals.reduce(0) { $0 + $1.kcal }) kcal")
                    }
                    .padding(.bottom, 10)
                }
            }
        }
        
    }
    
}


struct CustomDivider: View {
    var color: Color = .secondary.opacity(0.2)
    var height: CGFloat = 1

    var body: some View {
        Divider()
            .frame(height: height)
            .background(color)
    }
}


/*struct MealField: View {
    let label: String
    
    @Bindable var meal: Meal
    
    @State private var isLoading = false
    
    @FocusState private var isFocused: Bool
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @ObservedObject var gpt: GPT
    
    @Environment(\.modelContext) private var modelContext
    
    init(label: String, meal: Meal, gpt: GPT) {
        self.label = label
        self.meal = meal
        self.gpt = gpt
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(label)
                    .font(.title)
                Spacer()
                if isLoading {
                    ProgressView()
                } else {
                    Text("\(meal.kcal) kcal")
                        .foregroundStyle(.tint)
                }
            }
            
            TextEditor(text: $meal.details)
                .frame(height: 75)
                .scrollContentBackground(.hidden)
                .background(.secondary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($isFocused)
                .onChange(of: meal.details) { oldText, newText in
                    if newText.contains("\n") {
                        isFocused = false
                        meal.details = oldText
                        getKcal(of: meal.details)
                    }
                }
        }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("Ok", role: .cancel) { }
        }
    }
    
    func getKcal(of food: String) {
        Task {
            isLoading = true
            do {
                meal.kcal = try await gpt.getKcal(of: food)
                modelContext.insert(meal)
                try modelContext.save()
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
            isLoading = false
        }
    }
    
}*/



#Preview {
    MealView()
        .modelContainer(for: Meal.self, inMemory: true)
}
