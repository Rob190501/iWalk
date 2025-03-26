//
//  ModelTestView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 24/03/25.
//

import SwiftUI

struct ModelTestView: View {
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var stepsPredictor = StepsPredictor.shared
    
    @State private var kcal = ""
    
    @State private var excerciseMinutes = ""
    
    @State private var steps = 0
    
    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case kcal, exercise
    }
    
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Kcal")) {
                    TextField("", text: $kcal)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .kcal)
                }
                
                Section(header: Text("Minuti di esercizio")) {
                    TextField("", text: $excerciseMinutes)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .exercise)
                }
                
                Section {
                    Button {
                        focusedField = nil
                        
                        do {
                            steps = try stepsPredictor.predictSteps(forCalories: Int(kcal) ?? 0, forMinutes: Int(excerciseMinutes) ?? 0)
                            print(steps)
                        } catch {
                            alertMessage = error.localizedDescription
                            showingAlert = true
                        }
                    } label: {
                        Text("Prevedi")
                    }
                }
                
                Section(header: Text("Passi")) {
                    if steps < 0 {
                        Text("0")
                    } else {
                        Text("\(steps)")
                    }
                }
            }
        }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("Ok", role: .cancel) { }
        }
        .navigationTitle("Prova modello")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    
}

#Preview {
    ModelTestView()
}
