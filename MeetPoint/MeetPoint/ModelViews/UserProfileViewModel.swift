//
//  UserProfileViewModel.swift
//  MeetPoint
//

import Foundation
import Combine
import Networking

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published private(set) var user: User
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoadedOnce = false
    @Published var error: String?

    private let authService = AppNetworking.auth
    private let isCurrentUser: Bool

    init(initialUser: User, isCurrentUser: Bool = false) {
        self.user = initialUser
        self.isCurrentUser = isCurrentUser
    }

    var showsSkeleton: Bool {
        isLoading && !hasLoadedOnce
    }

    func loadProfile(force: Bool = false) async {
        if isLoading { return }
        if hasLoadedOnce && !force { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoadedOnce = true
        }

        if isCurrentUser, let refreshed = await fetchMyProfile() {
            user = refreshed
            error = nil
            return
        }

        if let userId = user.id, let refreshed = await fetchProfile(userId: userId) {
            user = refreshed
            error = nil
            return
        }

        if let refreshed = await fetchProfile(username: user.userName) {
            user = refreshed
            error = nil
        }
    }

    private func fetchMyProfile() async -> User? {
        let resource = Resource<UserProfileDTO, GetMyProfileRequest>(
            request: GetMyProfileRequest()
        )
        do {
            let dto = try await NetworkTask.fetch(authService, resource: resource)
            return dto.toUser(merging: user)
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .profile)
            return nil
        }
    }

    private func fetchProfile(userId: UUID) async -> User? {
        let resource = Resource<UserProfileDTO, GetUserProfileByIdRequest>(
            request: GetUserProfileByIdRequest(userId: userId)
        )
        do {
            let dto = try await NetworkTask.fetch(authService, resource: resource)
            return dto.toUser(merging: user)
        } catch {
            return nil
        }
    }

    private func fetchProfile(username: String) async -> User? {
        let resource = Resource<UserProfileDTO, GetUserProfileByUsernameRequest>(
            request: GetUserProfileByUsernameRequest(username: username)
        )
        do {
            let dto = try await NetworkTask.fetch(authService, resource: resource)
            return dto.toUser(merging: user)
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .profile)
            return nil
        }
    }
}
