//
//  AuthManager.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import Foundation
import Combine
import KeychainAccess

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let keychain = Keychain(service: "com.parrot.app")
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    var accessToken: String? {
        return keychain["accessToken"]
    }
    
    var refreshToken: String? {
        return keychain["refreshToken"]
    }
    
    init() {
        checkAuthenticationStatus()
    }
    
    private func checkAuthenticationStatus() {
        if let _ = accessToken, let username = keychain["username"] {
            isAuthenticated = true
            currentUser = username
        }
    }
    
    func login(username: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        let loginRequest = LoginRequest(username: username, password: password)
        guard let requestData = try? JSONEncoder().encode(loginRequest) else {
            isLoading = false
            errorMessage = "请求数据编码失败"
            return
        }
        
        let publisher: AnyPublisher<AuthResponse, APIError> = networkManager.performRequest(
            endpoint: "/auth/login",
            method: .POST,
            body: requestData,
            requiresAuth: false
        )
        
        publisher
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { [weak self] response in
                self?.saveAuthResponse(response)
                self?.isAuthenticated = true
                self?.currentUser = response.username
            }
        )
        .store(in: &cancellables)
    }
    
    func register(username: String, password: String, email: String?, nickname: String?) {
        isLoading = true
        errorMessage = nil
        
        let registerRequest = RegisterRequest(
            username: username,
            password: password,
            email: email,
            phone: nil,
            nickname: nickname
        )
        
        guard let requestData = try? JSONEncoder().encode(registerRequest) else {
            isLoading = false
            errorMessage = "请求数据编码失败"
            return
        }
        
        let publisher: AnyPublisher<AuthResponse, APIError> = networkManager.performRequest(
            endpoint: "/auth/register",
            method: .POST,
            body: requestData,
            requiresAuth: false
        )
        
        publisher
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { [weak self] response in
                self?.saveAuthResponse(response)
                self?.isAuthenticated = true
                self?.currentUser = response.username
            }
        )
        .store(in: &cancellables)
    }
    
    func checkUsername(_ username: String) -> AnyPublisher<Bool, APIError> {
        let publisher: AnyPublisher<UsernameCheckResponse, APIError> = networkManager.performRequest(
            endpoint: "/auth/check?username=\(username)",
            method: .GET,
            requiresAuth: false
        )
        
        return publisher
            .map { (response: UsernameCheckResponse) -> Bool in
                return response.exists
            }
            .eraseToAnyPublisher()
    }
    
    func refreshAccessToken() {
        guard let refreshToken = refreshToken else {
            logout()
            return
        }
        
        let refreshRequest = RefreshRequest(refreshToken: refreshToken)
        guard let requestData = try? JSONEncoder().encode(refreshRequest) else {
            logout()
            return
        }
        
        let publisher: AnyPublisher<AuthResponse, APIError> = networkManager.performRequest(
            endpoint: "/auth/refresh",
            method: .POST,
            body: requestData,
            requiresAuth: false
        )
        
        publisher
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(_) = completion {
                    self?.logout()
                }
            },
            receiveValue: { [weak self] response in
                self?.saveAuthResponse(response)
            }
        )
        .store(in: &cancellables)
    }
    
    func logout() {
        keychain["accessToken"] = nil
        keychain["refreshToken"] = nil
        keychain["username"] = nil
        
        isAuthenticated = false
        currentUser = nil
        errorMessage = nil
    }
    
    private func saveAuthResponse(_ response: AuthResponse) {
        keychain["accessToken"] = response.accessToken
        keychain["refreshToken"] = response.refreshToken
        keychain["username"] = response.username
    }
}
