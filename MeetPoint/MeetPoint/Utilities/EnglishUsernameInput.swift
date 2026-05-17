//
//  EnglishUsernameInput.swift
//  MeetPoint
//

import Foundation

enum EnglishUsernameInput {
    private static let allowedScalars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")

    static func sanitized(_ string: String) -> String {
        String(string.unicodeScalars.filter { allowedScalars.contains($0) })
    }
}
