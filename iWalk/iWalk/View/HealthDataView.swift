//
//  HealthDataView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//


import SwiftUI

struct HealthDataView: View {
    //@State private var errorMessage: String?
    @ObservedObject private var healthData = HealthData()
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack {
            if healthData.data.isEmpty {
                Text("Nessun dato disponibile")
                    .foregroundColor(.gray)
                
                Button {
                    do {
                        let years = 3
                        try healthData.fetchHealthData(since: years)
                    }
                    catch {
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                } label: {
                    Text("Fetch")
                }
                
            } else {
                Button {
                    do {
                        try healthData.saveCSVandCreateModel()
                    }
                    catch {
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                } label: {
                    Text("Salva e crea modello")
                }
                
                Button {
                    do {
                        let kcal = 768
                        let steps = try healthData.predictSteps(forCalories: kcal)
                        alertMessage = "\(steps) passi per \(kcal) kcal"
                    }
                    catch {
                        alertMessage = error.localizedDescription
                    }
                    showingAlert = true
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
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("Ok", role: .cancel) { }
        }
    }
    
    func formatDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.string(from: date)
    }
    
}

#Preview {
    HealthDataView()
}
