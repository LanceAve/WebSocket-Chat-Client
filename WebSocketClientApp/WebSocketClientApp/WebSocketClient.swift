//
//  WebSocketManager.swift
//  WebSocketClientApp
//
//  Created by Lance on 2025-03-20.
//  Modifed on 2025-05-13

import Foundation

// WebSocketClient.swift
// This class acts as a WebSocket transport layer with no UI state.
// It handles connection lifecycle and message transport, providing
// incoming messages via a callback closure to the ViewModel.

struct ChatMessage: Codable {
    let username: String
    let message: String
    let timestamp: String

    // Human-readable timestamp derived from ISO 8601 format
    var formattedTimestamp: String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: timestamp) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm a"
            return dateFormatter.string(from: date)
        }
        return timestamp  // Fallback if parsing fails
    }
}

// Handles WebSocket connection lifecycle and message transport
// This class does not conform to ObservableObject and holds no UI state.
// The onMessageReceived closure is the only bridge to the ViewModel for incoming messages.
class WebSocketClient {
    // Callback invoked when a new ChatMessage is received
    var onMessageReceived: ((ChatMessage) -> Void)?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var shouldReconnect = true

    init() {
        connectToWebSocket()
    }
    
    // Establishes a WebSocket connection and initiates handshake
    func connectToWebSocket() {
        guard let url = URL(string: "ws://localhost:8080") else {
            print("Invalid WebSocket URL")
            return
        }
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Send client identification on connect
        let handshakeMessage = ["username": "SwiftClient", "clientType": "Swift"]
        sendRawMessage(messageData: handshakeMessage)

        receiveMessage() // Begin listening loop
    }
    
    // Public API for sending plain text messages
    func sendMessage(_ message: String) {
        let messageData = ["message": message]
        sendRawMessage(messageData: messageData)
    }
    
    // Encodes and sends raw JSON data over the socket
    private func sendRawMessage(messageData: [String: String]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
            let messageToSend = URLSessionWebSocketTask.Message.data(jsonData)
            
            webSocketTask?.send(messageToSend) { error in
                if let error = error {
                    print("Error sending message: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Failed to encode message")
        }
    }
    
    // Continuously receives messages and triggers callback
    func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error.localizedDescription)")
                self?.attemptReconnection()

            case .success(let message):
                switch message {
                case .string(let text):
                    // Attempt to decode incoming string as ChatMessage
                    if let data = text.data(using: .utf8),
                       let chatMessage = try? JSONDecoder().decode(ChatMessage.self, from: data) {

                        print("RAW TIMESTAMP RECEIVED: \(chatMessage.timestamp)")
                        
                        // Notify consumer of new message
                        DispatchQueue.main.async {
                            self?.onMessageReceived?(chatMessage)
                        }

                        print("FORMATTED TIMESTAMP (Using Computed Property): \(chatMessage.formattedTimestamp)")
                    }
                default:
                    break // Ignoring unsupported message formats for now
                }
                self?.receiveMessage() // Loop back to continue listening
            }
        }
    }
    
    // Retry connection after a short delay if allowed
    func attemptReconnection() {
        if !shouldReconnect { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            print("Attempting to reconnect...")
            self?.connectToWebSocket()
        }
    }
    
    // Gracefully closes the connection and disables auto-reconnect
    func closeConnection() {
        shouldReconnect = false
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        print("WebSocket connection manually closed")
    }
    
    // Manually triggers reconnection if previously closed
    func reconnectManually() {
        shouldReconnect = true
        connectToWebSocket()
    }
}
