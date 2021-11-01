//
//  File.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 30..
//

import Foundation
import Vapor

enum EventError {
    case eventTitleTaken
    case notApplyable
}

extension EventError: AbortError {
    var description: String {
        reason
    }
    var status: HTTPResponseStatus {
        switch self {
        case .eventTitleTaken:
            return .conflict
        case .notApplyable:
            return .conflict
        }
    }
    var reason: String {
        switch self {
        case .eventTitleTaken:
            return "Event title already taken"
        case .notApplyable:
            return "Event is not applyable"
        }
    }
}
