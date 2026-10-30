//
//  AuthUser.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import Foundation

struct AuthUser: Equatable{
    
    let uid : String;
    let email : String;
    let name : String;
    
}

extension AuthUser {
    
    var initials: String {
        let words = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .prefix(2)
        let letters = words.compactMap { $0.first }.map(String.init).joined()
        if !letters.isEmpty { return letters.uppercased() }
        return String(email.prefix(1)).uppercased()
    }
}
