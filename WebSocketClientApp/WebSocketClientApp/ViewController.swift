//
//  ViewController.swift
//  WebSocketClientApp
//
//  Created by Lance on 2025-03-18.
//  Modified and cleaned up on 2025-05-13

import UIKit
class ViewController: UIViewController {
    
    // Basic session config – no delegate needed for simple WebSocket handling
    var webSocketTask: URLSessionWebSocketTask?
    
    // UI Elements
    @IBOutlet weak var messagesTextView: UITextView!
    @IBOutlet weak var messageTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        connectToWebSocket()                                // Establish the WebSocket connection
    }
    
    // Function responsible for connecting to the WebSocket
    func connectToWebSocket() {
        let url = URL(string: "ws://localhost:8080")!       // WebSocket server URL
        let session = URLSession(configuration: .default)   // Create a URLSession configuration
        webSocketTask = session.webSocketTask(with: url)    // Initialize the WebSocket task
        
        webSocketTask?.resume()                             // Start the WebSocket task
        receiveMessage()                                    // Start receiving messages
    }
    
    // Function that will be used to send messages to the server
    func sendMessage() {
        
        guard let message = messageTextField.text, !message.isEmpty else { return }     // Get the message text from the text field
        let messageToSend = URLSessionWebSocketTask.Message.string(message)             // Create a WebSocket message to send
        
        // Send the message
        webSocketTask?.send(messageToSend) { error in
            
            // Check if message send was successful
            if let error = error {
                print("Error sending message: \(error)")
            } else {
                print("Message sent: \(message)")
                
                // Clear the message field after sending
                DispatchQueue.main.async {
                    self.messageTextField.text =
                    ""
                }
            }
        }
    }
    
    // use [weak self] to avoid retain cycles and memory leaks
    // Listen for the next WebSocket message
    func receiveMessage() {
        
        // Avoid retain cycle due to recursive closure capturing self
        webSocketTask?.receive { [weak self] result in
            
            // message status switch cases for success and failure
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    
                    // Append received message to UITextView on main thread (UI update)
                    DispatchQueue.main.async {
                        self?.messagesTextView.text.append("\(text)\n")
                    }
                    // Continue receiving next message
                    self?.receiveMessage()
                case .data(let data):
                    print("Received binary data: \(data)")
                @unknown default:
                    break
                }
            }
        }
    }
    
    // Button action to send a message
    @IBAction func sendButtonTapped(_
                                    sender: UIButton) {
        sendMessage()
    }
    // Button action to close WebSocket connection
    @IBAction func closeButtonTapped(_
                                     sender: UIButton) {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        print("WebSocket connection closed")
    }
    
}
