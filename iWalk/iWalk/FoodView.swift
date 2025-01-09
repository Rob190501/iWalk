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
    @State private var userQuestion: String = ""
    @State private var botAnswer: String = "Risposta..."

        var body: some View {
            VStack {
                TextField("Inserisci una domanda", text: $userQuestion)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button {
                    botAnswer = "EEEEE"
                    test()
                } label: {
                    Text("Invia domanda")
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
                .init(role: .system, content: "Rispondi solo con il numero intero totale delle calorie degli alimenti forniti, senza aggiungere testo. Se non ci sono alimenti validi o sei incerto, rispondi con 0.")!,
                .init(role: .user, content: "500 grammi Pizza margherita")!
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
                }
            case .failure(let failure):
                print("Errore: ")
                print(failure)
            }
        }
    }
}

#Preview {
    FoodView()
}
