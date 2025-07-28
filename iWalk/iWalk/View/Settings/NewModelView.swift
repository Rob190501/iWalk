//
//  HealthDataView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//


import SwiftUI

struct NewModelView: View {
    private let healthService = HealthService.shared
    
    private let stepsPredictor = StepsPredictor.shared
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @State private var generateSyntheticData = true
    @State private var records = 100
    
    @State private var years = 5
    
    @State private var removeOutliers = true
    @State private var tolerance = 0.010
    
    @State private var isFetching = false
    
    @State private var data: [HealthData] = [] {
        didSet {
            calculateMAE()
        }
    }
    
    @State private var folds = 5
    
    @State private var MAE = 0
    
    
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Rimozione outlier", isOn: $removeOutliers)
                    
                    Stepper("Tolleranza: ±\(String(format: "%.3f", tolerance)) kcal/passo", value: $tolerance, in: 0.01...0.05, step: 0.005)
                        .disabled(!removeOutliers)
                        .foregroundStyle(removeOutliers ? Color.primary : Color.gray.opacity(0.7))
                    
                    Toggle("Generazione record sintetici", isOn: $generateSyntheticData)
                        .disabled(!removeOutliers)
                        .foregroundStyle(removeOutliers ? Color.primary : Color.gray.opacity(0.7))
                    
                    Stepper("Numero record: \(records)", value: $records, in: 100...1000, step: 100)
                        .disabled(!generateSyntheticData || !removeOutliers)
                        .foregroundStyle(generateSyntheticData && removeOutliers ? Color.primary : Color.gray.opacity(0.7))

                    Stepper("Anni da includere: \(years)", value: $years, in: 1...10, step: 1)
                    
                    Button {
                        Task {
                            isFetching = true
                            do {
                                let tempData = try await healthService.fetchHealthData(
                                    since: years,
                                    removeOutliers: removeOutliers,
                                    tolerance: tolerance,
                                    generateSyntheticData: generateSyntheticData && removeOutliers,
                                    syntheticRecords: records
                                )
                                
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
                                try await stepsPredictor.saveCSVandCreateModel(data: data)
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
                
                if(!data.isEmpty) {
                    Section(header: Text("MAE")) {
                        Stepper("Numero folds: \(folds)", value: $folds, in: 5...10, step: 5)
                            .onChange(of: folds) {
                                calculateMAE()
                            }
                        
                        Text("MAE: ± \(MAE)")
                    }
                    
                    Section(header: Text("Dataset")) {
                        List(data) { record in
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
        .navigationTitle("Nuovo modello")
        .navigationBarTitleDisplayMode(.inline)
        
    }
    
    func formatDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.string(from: date)
    }
    
    func calculateMAE() {
        Task {
            do {
                MAE = try await stepsPredictor.kFoldValidation(data: data, k: folds)
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
                MAE = 0
            }
        }
    }
    
}

#Preview {
    NewModelView()
}
