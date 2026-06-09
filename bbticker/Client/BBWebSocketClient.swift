//
//  BBWebSocketClient.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 13/07/2025.
//
/*
import Foundation
import Combine

// MARK: - WebSocket Client Delegate
protocol BBWebSocketClientDelegate: AnyObject {
    func webSocketClient(_ client: BBWebSocketClient, didReceiveWalletData data: BBWalletData)
    func webSocketClient(_ client: BBWebSocketClient, didChangeConnectionStatus status: ConnectionStatus)
    func webSocketClient(_ client: BBWebSocketClient, didFailWithError error: String)
    func webSocketClientDidConnect(_ client: BBWebSocketClient)
    func webSocketClientDidDisconnect(_ client: BBWebSocketClient)
}

// MARK: - WebSocket Client
final class BBWebSocketClient: NSObject, URLSessionWebSocketDelegate {
    // MARK: - Properties
    private let apiKey: String
    private let apiSecret: String
    private let webSocketURL = URL(string: "wss://stream.bybit.com/v5/private")!
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    private var isAuthenticated = false
    private var shouldReconnect = false
    
    // Reconnection logic
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let reconnectDelay: TimeInterval = 2.0
    
    weak var delegate: BBWebSocketClientDelegate?
    
    // MARK: - Initialization
    init(apiKey: String, apiSecret: String) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        super.init()
    }
    
    // MARK: - Public Interface
    func connect() {
        guard !isConnected else { return }
        
        shouldReconnect = true
        reconnectAttempts = 0
        attemptConnection()
    }
    
    func disconnect() {
        shouldReconnect = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        isAuthenticated = false
        delegate?.webSocketClientDidDisconnect(self)
    }
    
    // MARK: - Private Methods
    private func attemptConnection() {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = session.webSocketTask(with: webSocketURL)
        webSocketTask?.resume()
        delegate?.webSocketClient(self, didChangeConnectionStatus: .connecting)
    }
    
    private func attemptReconnection() {
        guard shouldReconnect else { return }
        
        if reconnectAttempts >= maxReconnectAttempts {
            delegate?.webSocketClient(self, didFailWithError: "Failed to reconnect after \(maxReconnectAttempts) attempts")
            return
        }
        
        reconnectAttempts += 1
        delegate?.webSocketClient(self, didChangeConnectionStatus: .connecting)
        attemptConnection()
    }
    
    // MARK: - Authentication
    private func authenticate() {
        print("🔐 Starting authentication...")
        let expires = String(Int(Date().timeIntervalSince1970 * 1000) + 10000)
        let param = "GET/realtime" + expires
        let signature = param.hmacSHA256(key: apiSecret)
        
        let authMessage: [String: Any] = [
            "op": "auth",
            "args": [apiKey, expires, signature]
        ]
        
        print("📤 Sending auth message: \(authMessage)")
        send(message: authMessage)
    }
    
    private func subscribeToWallet() {
        print("📡 Subscribing to wallet updates")
        let subscribeMessage: [String: Any] = [
            "op": "subscribe",
            "args": ["wallet"]
        ]
        send(message: subscribeMessage)
    }
    
    // MARK: - Message Handling
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.delegate?.webSocketClient(self, didFailWithError: error.localizedDescription)
                }
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    print("Received data: \(data.count) bytes")
                @unknown default:
                    print("Unknown message type")
                }
            }
            self?.receiveMessage()
        }
    }
    
    private func handleMessage(_ message: String) {
        print("📨 Received WebSocket message: \(message)")
        
        guard let data = message.data(using: .utf8) else {
            print("❌ Failed to convert message to data")
            return
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON from message")
            return
        }
        
        print("✅ Parsed JSON: \(json)")
        
        // Handle authentication response
        if json["op"] as? String == "auth" {
            print("🔐 Handling authentication response")
            handleAuthenticationResponse(json)
            return
        }
        
        // Handle wallet data
        if json["topic"] as? String == "wallet" {
            print("💰 Received wallet topic message")
            if let walletDataArray = json["data"] as? [[String: Any]] {
                print("📊 Wallet data array: \(walletDataArray)")
                if let walletData = parseWalletData(from: walletDataArray) {
                    print("✅ Successfully parsed wallet data: totalEquity=\(walletData.totalEquity), walletBalance=\(walletData.walletBalance)")
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.delegate?.webSocketClient(self, didReceiveWalletData: walletData)
                    }
                } else {
                    print("❌ Failed to parse wallet data from array")
                }
            } else {
                print("❌ No wallet data array found in message")
            }
        } else {
            print("ℹ️ Message topic: \(json["topic"] as? String ?? "nil")")
            
            // Handle subscription responses
            if json["op"] as? String == "subscribe" {
                if let success = json["success"] as? Bool, success {
                    print("✅ Successfully subscribed to wallet updates")
                } else {
                    print("❌ Failed to subscribe to wallet updates: \(json["retMsg"] ?? "Unknown error")")
                }
            }
            
            // Handle ping/pong
            if json["op"] as? String == "pong" {
                print("🏓 Received pong")
            }
        }
    }
    
    private func handleAuthenticationResponse(_ json: [String: Any]) {
        print("🔐 Authentication response: \(json)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let success = json["success"] as? Bool, success {
                print("✅ WebSocket authentication successful")
                self.isAuthenticated = true
                self.delegate?.webSocketClient(self, didChangeConnectionStatus: .connected)
                self.delegate?.webSocketClientDidConnect(self)
                self.subscribeToWallet()
            } else {
                let retMsg = json["retMsg"] as? String ?? "Authentication failed"
                print("❌ WebSocket authentication failed: \(retMsg)")
                self.delegate?.webSocketClient(self, didFailWithError: retMsg)
            }
        }
    }
    
    private func parseWalletData(from walletDataArray: [[String: Any]]) -> BBWalletData? {
        print("🔍 Parsing wallet data from: \(walletDataArray)")
        
        guard let firstWalletItem = walletDataArray.first else {
            print("❌ No wallet items in array")
            return nil
        }
        
        print("📋 First wallet item: \(firstWalletItem)")
        
        guard let totalEquity = firstWalletItem["totalEquity"] as? String else {
            print("❌ No totalEquity found in wallet item")
            return nil
        }
        
        guard let coins = firstWalletItem["coin"] as? [[String: Any]] else {
            print("❌ No coin array found in wallet item")
            return nil
        }
        
        print("🪙 Coins array: \(coins)")
        
        guard let usdtCoin = coins.first(where: { $0["coin"] as? String == "USDT" }) else {
            print("❌ No USDT coin found in coins array")
            print("Available coins: \(coins.compactMap { $0["coin"] as? String })")
            return nil
        }
        
        print("💵 USDT coin data: \(usdtCoin)")
        
        guard let walletBalance = usdtCoin["walletBalance"] as? String else {
            print("❌ No walletBalance found in USDT coin")
            return nil
        }
        
        print("✅ Successfully parsed: totalEquity=\(totalEquity), walletBalance=\(walletBalance)")
        return BBWalletData(totalEquity: totalEquity, walletBalance: walletBalance)
    }
    
    // MARK: - URLSessionWebSocketDelegate
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("🔗 WebSocket connection opened")
        isConnected = true
        reconnectAttempts = 0
        authenticate()
        receiveMessage()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
        isAuthenticated = false
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.shouldReconnect {
                DispatchQueue.main.asyncAfter(deadline: .now() + self.reconnectDelay) {
                    self.attemptReconnection()
                }
            } else {
                self.delegate?.webSocketClientDidDisconnect(self)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            isConnected = false
            isAuthenticated = false
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.delegate?.webSocketClient(self, didFailWithError: error.localizedDescription)
                
                if self.shouldReconnect {
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.reconnectDelay) {
                        self.attemptReconnection()
                    }
                }
            }
        }
    }
    
    private func send(message: [String: Any]) {
        guard let webSocketTask = webSocketTask,
              isConnected,
              let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to send message: not connected or invalid data")
            return
        }
        
        print("📤 Sending WebSocket message: \(jsonString)")
        webSocketTask.send(.string(jsonString)) { error in
            if let error = error {
                print("❌ Error sending message: \(error)")
            } else {
                print("✅ Message sent successfully")
            }
        }
    }
}
*/
