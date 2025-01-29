//
//  HealthDataView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//


import SwiftUI

struct HealthDataView: View {
    @State private var errorMessage: String?
    @ObservedObject private var healthData = HealthData()
    
    var body: some View {
        VStack {
            if let errorMessage = errorMessage {
                Text("Errore: \(errorMessage)")
                    .foregroundColor(.red)
            } else if healthData.data.isEmpty {
                Text("Nessun dato disponibile")
                    .foregroundColor(.gray)
                
                Button {
                    healthData.fetchHealthData(completion: printError)
                } label: {
                    Text("Fetch")
                }
                
            } else {
                Button {
                    healthData.saveToCSV(completion: printError)
                } label: {
                    Text("Salva")
                }
                
                
                Button {
                    healthData.trainModel()
                } label: {
                    Text("Allena")
                }
                
                Button {
                    healthData.predictSteps(forCalories: 700.0)
                } label: {
                    Text("Prevedi")
                }
                
                List(healthData.data, id: \.date) { record in
                    HStack {
                        Text(formatDate(date: record.date))
                        Spacer()
                        Text("\(record.steps) passi")
                        Spacer()
                        Text("\(record.calories) kcal")
                    }
                }
            }
        }
    }
    
    func formatDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.string(from: date)
    }
    
    func printError(errorMessage: String) {
        self.errorMessage = errorMessage
    }
    
}

#Preview {
    HealthDataView()
}
