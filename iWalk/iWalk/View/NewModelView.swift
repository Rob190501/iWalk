//
//  HealthDataView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//


import SwiftUI

struct NewModelView: View {
    private let healthData = HealthData()
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @State private var isOn = true
    
    @State private var years = 5
    
    @State private var tolerance = 0.025
    
    @State private var isFetching = false
    
    @State private var data: [(date: Date, steps: Int, calories: Int)] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Abilita rimozione outlier", isOn: $isOn)
                    
                    Stepper("Tolleranza: ±\(String(format: "%.3f", tolerance)) kcal/passo", value: $tolerance, in: 0.01...0.05, step: 0.005)
                        .disabled(!isOn)
                        .foregroundStyle(isOn ? Color.primary : Color.gray.opacity(0.7))

                        
                    
                    Stepper("Anni da includere: \(years)", value: $years, in: 1...10, step: 1)
                    
                    Button {
                        Task {
                            isFetching = true
                            do {
                                
                                let tempData = try await healthData.fetchHealthData(since: years, removeOutliers: isOn, tolerance: tolerance)
                                
                                withAnimation {
                                    data = tempData
                                }
                                
                            } catch {
                                alertMessage = error.localizedDescription
                                showingAlert = true
                            }
                            isFetching = false
                        }
                    } label: {
                        HStack {
                            Text("Recupera dati")
                            
                            if(isFetching) {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                }
                
                Section {
                    Button {
                        Task {
                            do {
                                try await healthData.saveCSVandCreateModel(data: data)
                                alertMessage = "Modello creato e salvato"
                            } catch {
                                alertMessage = error.localizedDescription
                            }
                            showingAlert = true
                        }
                    } label: {
                        Text("Crea modello")
                    }
                    .disabled(data.isEmpty)
                }
                
                Section {
                    List(data, id: \.date) { record in
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
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("Ok", role: .cancel) { }
        }
        .navigationTitle("Nuovo modello")
        .navigationBarTitleDisplayMode(.inline)
        
    }
    
    func formatDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.string(from: date)
    }
    
}

#Preview {
    NewModelView()
}
