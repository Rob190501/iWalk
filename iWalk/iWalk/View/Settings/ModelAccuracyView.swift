//
//  ModelAccuracyView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 24/03/25.
//

import SwiftUI

struct ModelAccuracyView: View {
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @StateObject private var storage = HealthDataStorage()
    
    private var stepsPredictor = StepsPredictor.shared
    
    @State private var folds = 5
    
    @State private var mae: Int = 0
    @State private var isCalculating = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Numero folds: \(folds)", value: $folds, in: 5...10, step: 5)
                    
                    HStack {
                        Text("MAE: ± \(mae)")
                        if isCalculating {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                    
                if(!storage.healthData.isEmpty) {
                    Section(header: Text("Dataset")) {
                        List(storage.healthData) { record in
                            HStack {
                                Text(formatDate(date: record.date))
                                Spacer()
                                Text("\(record.steps) passi")
                                Spacer()
                                Text("\(record.exerciseMinutes) minuti")
                                Spacer()
                                Text("\(record.calories) kcal")
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
        }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("Ok", role: .cancel) { }
        }
        .navigationTitle("Precisione modello")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            calculateMAE()
        }
        .onChange(of: folds) { _, _ in
            calculateMAE()
        }
    }
    
    private func calculateMAE() {
        guard !storage.healthData.isEmpty else {
            mae = 0
            return
        }
        
        isCalculating = true
        
        Task {
            do {
                let result = try await stepsPredictor.kFoldValidation(data: storage.healthData, k: folds)
                await MainActor.run {
                    self.mae = result
                    self.isCalculating = false
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = error.localizedDescription
                    self.showingAlert = true
                    self.mae = 0
                    self.isCalculating = false
                }
            }
        }
    }
    
    func formatDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.string(from: date)
    }
}

#Preview {
    ModelAccuracyView()
}
