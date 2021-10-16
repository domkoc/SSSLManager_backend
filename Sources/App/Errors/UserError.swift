//
//  UserError.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 16..
//

import Vapor

enum UserError {
    case usernameTaken
}

extension UserError: AbortError {
    var description: String {
        reason
    }
    var status: HTTPResponseStatus {
        switch self {
        case .usernameTaken: return .conflict
        }
    }
    var reason: String {
        switch self {
        case .usernameTaken: return "Username already taken"
        }
    }
}
