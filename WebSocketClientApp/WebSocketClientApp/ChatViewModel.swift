//
//  ChatViewModel.swift
//  WebSocketClientApp
//
//  Created by Lance on 2025-05-13.
//

import Foundation
import Combine

/// ViewModel responsible for handling chat UI state and delegating network communication.
/// Acts as a bridge between SwiftUI views and the WebSocket client layer.
class ChatViewModel: ObservableObject {
    /// UI-bound list of chat messages to render
    @Published var messages: [ChatMessage] = []
    
    /// Input field binding — reflects user-typed text
    @Published var inputMessage: String = ""

    /// Handles WebSocket connection and message transmission
    private let socketClient: WebSocketClient

    /// Initializes with a socket client (default: WebSocketManager).
    /// Sets up message subscription and initiates connection.
    init(socketClient: WebSocketClient = WebSocketClient()) {
        self.socketClient = socketClient

        // Listen for incoming messages and update UI state
        self.socketClient.onMessageReceived = { [weak self] message in
            DispatchQueue.main.async {
                self?.messages.append(message)
            }
        }

        // Start connection immediately on ViewModel init
        socketClient.connectToWebSocket()
    }

    /// Sends the current input message over the WebSocket.
    /// Clears the input field afterward.
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        socketClient.sendMessage(inputMessage)
        inputMessage = ""
    }

    /// Ensures WebSocket is cleanly closed if ViewModel is deallocated
    deinit {
        socketClient.closeConnection()
    }
}
