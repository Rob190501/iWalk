//
//  ModelAccuracyView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 24/03/25.
//

import SwiftUI

struct ModelAccuracyView: View {
    
    @StateObject private var storage = HealthDataStorage()
    
    private var stepsPredictor = StepsPredictor.shared
    
    @State private var folds = 5
    
    private var MAE: Int {
        do {
            return try stepsPredictor.kFoldValidation(data: storage.healthData, k: folds)
        } catch {
            return -1
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Numero folds: \(folds)", value: $folds, in: 5...10, step: 5)
                    
                    Text("MAE: ± \(MAE)")
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
        .navigationTitle("Precisione modello")
        .navigationBarTitleDisplayMode(.inline)
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
