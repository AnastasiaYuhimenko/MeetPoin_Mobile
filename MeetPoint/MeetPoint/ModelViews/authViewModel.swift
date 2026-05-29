//
//  authViewModel.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 15.05.2026.
//

import Foundation
import Combine
import Networking

@MainActor
final class AuthViewModel: ObservableObject {
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoggedIn = false
    @Published var isUsernameAvailable: Bool?
    @Published var usernameCheckFailed = false
    
    private let urlService = AppNetworking.auth
    
    private(set) var currentUser: UserResponseDTO?
    
    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "accessToken") }
        set { UserDefaults.standard.set(newValue, forKey: "accessToken") }
    }
    
    init() {
        isLoggedIn = accessToken != nil
        urlService.onUnauthorized = {
            Task { @MainActor [weak self] in
                self?.logout()
            }
        }
    }
    
    func checkUsername(_ username: String) async {
        isUsernameAvailable = nil
        usernameCheckFailed = false
        guard username.count >= 3 else { return }
        
        let resource = Resource<UsernameCheckResponseDTO, CheckUsernameRequest>(
            request: CheckUsernameRequest(username: username)
        )
        let service = urlService
        do {
            let response = try await NetworkTask.fetch(service, resource: resource)
            isUsernameAvailable = response.isAvailable
        } catch {
            isUsernameAvailable = nil
            usernameCheckFailed = true
        }
    }
    
    func register(user: User) async {
        isLoading = true
        errorMessage = nil
        
        let dto = UserCreateDTO(
            name: user.name,
            userName: user.userName,
            position: user.position.rawValue,
            password: user.password,
            tags: user.tags.map { $0.apiValue },
            about: user.about,
            telegram: user.telegram,
            email: user.email
        )
        
        let resource = Resource<UserResponseDTO, RegisterRequest>(
            request: RegisterRequest(userCreate: dto)
        )
        
        let service = urlService
        do {
            _ = try await NetworkTask.fetch(service, resource: resource)
            await auth(userName: user.userName, password: user.password)
        } catch {
            errorMessage = UserFacingNetworkMessage.message(for: error, context: .authentication)
            isLoading = false
        }
    }
    
    func auth(userName: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        let resource = Resource<LoginResponseDTO, LoginRequest>(
            request: LoginRequest(username: userName, password: password)
        )
        
        let service = urlService
        do {
            let response = try await NetworkTask.fetch(service, resource: resource)
            accessToken = response.accessToken
            isLoggedIn = true
        } catch {
            errorMessage = UserFacingNetworkMessage.message(for: error, context: .authentication)
        }
        
        isLoading = false
    }
    
    func logout() {
        accessToken = nil
        isLoggedIn = false
        currentUser = nil
        errorMessage = nil
    }
    
}
