//
//  MealField.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 29/01/25.
//

import SwiftUI

struct MealField: View {
    let label: String
    
    @Bindable var meal: Meal
    
    @State private var isLoading = false
    
    @FocusState private var isFocused: Bool
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let calorieBot = CalorieBot.shared
    
    @Environment(\.modelContext) private var modelContext
    
    init(label: String, meal: Meal) {
        self.label = label
        self.meal = meal
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
                meal.kcal = try await calorieBot.getKcal(of: food)
                modelContext.insert(meal)
                try modelContext.save()
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
            isLoading = false
        }
    }
    
}

#Preview {
    let sampleBreakfast = Meal(mealTime: .breakfast, details: "", kcal: 0)
    MealField(label: "Colazione", meal: sampleBreakfast)
        .padding(.horizontal)
}
