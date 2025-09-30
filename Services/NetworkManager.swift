//
//  NetworkManager.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import Foundation
import Combine
import KeychainAccess

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let baseURL = "https://jaychou.sbs/parrot/api"
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    private let keychain = Keychain(service: "com.parrot.app")
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Generic Request Methods
    func performRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        requiresAuth: Bool = true
    ) -> AnyPublisher<T, APIError> {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return Fail(error: APIError(message: "无效的URL")).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("*/*", forHTTPHeaderField: "Accept")
        request.addValue("ParrotApp/1.0", forHTTPHeaderField: "User-Agent")
        
        if requiresAuth, let token = keychain["accessToken"] {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Using auth token for \(endpoint): \(token.prefix(20))...")
        } else if requiresAuth {
            print("⚠️  No auth token found for \(endpoint)")
        } else {
            print("🔓 No auth required for \(endpoint)")
        }
        
        if let body = body {
            request.httpBody = body
            print("📤 Request body for \(endpoint): \(String(data: body, encoding: .utf8) ?? "[binary data]")")
        }
        
        print("🌐 Making \(method.rawValue) request to: \(url.absoluteString)")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> T in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError(message: "无效响应")
                }
                
                if httpResponse.statusCode == 401 {
                    // Token expired, try to refresh
                    throw APIError(message: "Token已过期")
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "网络请求失败"
                    print("API Error - Status: \(httpResponse.statusCode), Response: \(errorMessage)")
                    throw APIError(message: errorMessage)
                }
                
                // Debug: Print the raw response data
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🌐 API Response for \(endpoint):")
                    print("📄 Status Code: \(httpResponse.statusCode)")
                    print("📄 Response Data: \(responseString)")
                    
                    // If response is too long, truncate it for readability
                    if responseString.count > 1000 {
                        let truncated = String(responseString.prefix(500)) + "... [truncated] ..." + String(responseString.suffix(500))
                        print("📄 Truncated Response: \(truncated)")
                    }
                } else {
                    print("🌐 API Response for \(endpoint): [Unable to convert data to string]")
                    print("📄 Status Code: \(httpResponse.statusCode)")
                    print("📄 Data length: \(data.count) bytes")
                }
                
                // Handle boolean responses
                if T.self == Bool.self {
                    let responseString = String(data: data, encoding: .utf8) ?? "false"
                    let boolValue = responseString.lowercased() == "true"
                    return boolValue as! T
                }
                
                // Handle empty responses
                if data.isEmpty {
                    print("⚠️  Empty response data for \(endpoint)")
                    throw APIError(message: "The data couldn't be read because it is missing.")
                }
                
                // Try to decode the response
                do {
                    let decodedResponse = try self.decoder.decode(T.self, from: data)
                    print("✅ Successfully decoded response for \(endpoint)")
                    return decodedResponse
                } catch let decodingError as DecodingError {
                    print("❌ Decoding error for \(endpoint): \(decodingError)")
                    
                    // Provide more detailed decoding error information
                    switch decodingError {
                    case .dataCorrupted(let context):
                        print("   Data corrupted: \(context.debugDescription)")
                    case .keyNotFound(let key, let context):
                        print("   Key '\(key.stringValue)' not found: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("   Type mismatch for \(type): \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("   Value not found for \(type): \(context.debugDescription)")
                    @unknown default:
                        print("   Unknown decoding error")
                    }
                    
                    throw APIError(message: "Failed to decode response: \(decodingError.localizedDescription)")
                } catch {
                    print("❌ Unknown error decoding \(endpoint): \(error)")
                    throw APIError(message: "Unknown error: \(error.localizedDescription)")
                }
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError(message: error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    func performSimpleRequest(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        requiresAuth: Bool = true
    ) -> AnyPublisher<String, APIError> {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return Fail(error: APIError(message: "无效的URL")).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth, let token = keychain["accessToken"] {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> String in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError(message: "无效响应")
                }
                
                if httpResponse.statusCode == 401 {
                    throw APIError(message: "Token已过期")
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "网络请求失败"
                    throw APIError(message: errorMessage)
                }
                
                return String(data: data, encoding: .utf8) ?? ""
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError(message: error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}