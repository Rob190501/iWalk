//
//  FoodView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//

import SwiftUI
import Foundation

import OpenAI

struct FoodView: View {
    @State private var food: String = ""
    @State private var botAnswer: String = "..."
    
    @Environment(\.colorScheme) var colorScheme
    
    @FocusState private var isFocused: Bool // Stato del focus per la TextField
    
    var body: some View {
        VStack {
            TextField("Inserisci cibo", text: $food)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isFocused)
                
            Button {
                test()
            } label: {
                Text("Invia")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
                
            Text("Risposta:")
                .font(.headline)
                .padding(.top)
                
            Text(botAnswer)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.top)
        }
        .padding()
    }
    
    
    
    func test() {
        
        let openAI = OpenAI(
            apiToken: ""
        )
        
        let query = ChatQuery(
            messages: [
                .init(role: .system, content: "Rispondi solo con il numero intero totale delle calorie degli alimenti forniti, senza aggiungere mai del testo, di nessun tipo. Se non ci sono alimenti validi o sei incerto, rispondi con 0.")!,
                .init(role: .user, content: food)!
            ],
            model: .gpt3_5Turbo
        )
        
        openAI.chats(query: query) { result in
            switch result {
            case .success(let success):
                guard let choice = success.choices.first else { return }
                guard let message = choice.message.content?.string else { return }
                DispatchQueue.main.async {
                    print(message)
                    botAnswer = "\(food) : \(message) kcal"
                }
            case .failure(let failure):
                print(failure)
                botAnswer = failure.localizedDescription
            }
        }
    }
}

#Preview {
    FoodView()
}
