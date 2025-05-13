//
//  ContentView.swift
//  WebSocketClientApp
//
//  Created by Lance on 2025-03-18.
//  Modified on 2025-05-13

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack {
            Text("WebSocket Chat")
                .font(.title)
                .padding()

            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(viewModel.messages.indices, id: \.self) { index in
                            let msg = viewModel.messages[index]
                            
                            VStack(alignment: .leading) {
                                Text("\(msg.username): \(msg.message)")
                                    .padding()
                                    .background(msg.username.contains("SwiftClient") ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                
                                Text(msg.formattedTimestamp)  // Now properly formats timestamp
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(index)  // Assign ID for scrolling
                        }
                    }
                }
                .padding()
                .onChange(of: viewModel.messages.count) { _ in
                    // Scroll to the latest message when messages update
                    withAnimation {
                        scrollViewProxy.scrollTo(viewModel.messages.count - 1, anchor: .bottom)
                    }
                }
            }

            HStack {
                TextField("Type a message...", text: $viewModel.inputMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
