//
//  UsersList.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI

struct UsersList: View {

    let users: [User]
    @State private var selectedUser: User?

    var body: some View {
        List {
            ForEach(users) { user in
                Button {
                    selectedUser = user
                } label: {
                    HStack {
                        Image(systemName: "person.circle")
                            .font(.title)
                        Text(user.displayName)
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                    .foregroundStyle(Color.appPurple)
                }
            }
        }
        .sheet(item: $selectedUser) { user in
            VStack {
                UserCellSheet(user: user)
                    .padding(.top, 24)
                Spacer()
            }
            .presentationDetents([.medium], selection: .constant(.large))
        }
    }
}

// MARK: - SwiftUI wrapper for UserCellView

struct UserCellSheet: UIViewRepresentable {
    let user: User
    var isFriend: Bool = true
    var hasOffer: Bool = false
    var isSelf: Bool = false
    var connectionState: ConnectionStatusState?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UserCellView {
        UserCellView()
    }

    func updateUIView(_ uiView: UserCellView, context: Context) {
        let userKey = userCacheKey
        if context.coordinator.cachedUserKey != userKey {
            context.coordinator.cachedUserKey = userKey
            context.coordinator.cachedSize = nil
        }
        uiView.configure(
            with: user,
            connectionState: connectionState,
            isFriend: isFriend,
            hasOffer: hasOffer,
            isSelf: isSelf
        )
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UserCellView, context: Context) -> CGSize? {
        if context.coordinator.cachedUserKey == userCacheKey,
           let cached = context.coordinator.cachedSize
        {
            return cached
        }

        let width = proposal.width ?? UIScreen.main.bounds.width
        uiView.frame = CGRect(x: 0, y: 0, width: width, height: UIView.layoutFittingExpandedSize.height)
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
        let size = uiView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        context.coordinator.cachedSize = size
        context.coordinator.cachedUserKey = userCacheKey
        return size
    }

    private var userCacheKey: String {
        var key = user.id?.uuidString ?? user.userName
        key += "|" + user.displayName
        if let connectionState {
            switch connectionState {
            case .contacts:
                key += "|contacts"
            case .incoming:
                key += "|incoming"
            case .outgoing:
                key += "|outgoing"
            case .none:
                key += "|none"
            case .unknown(let raw):
                key += "|unknown-\(raw)"
            }
        }
        return key
    }

    final class Coordinator {
        var cachedSize: CGSize?
        var cachedUserKey: String?
    }
}

#Preview {
    UsersList(users: [userDevelop.user, userDevelop.user, userDevelop.user])
}
