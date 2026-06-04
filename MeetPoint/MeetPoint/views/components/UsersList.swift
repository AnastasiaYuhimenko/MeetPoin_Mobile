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
        NavigationStack {
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
            .navigationDestination(item: $selectedUser) { user in
                UserProfileDestination(user: user)
            }
        }
    }
}

#Preview {
    UsersList(users: [userDevelop.user, userDevelop.user, userDevelop.user])
}
