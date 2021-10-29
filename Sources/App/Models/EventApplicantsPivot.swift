//
//  EventApplicantsPivot.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 29..
//

import Foundation
import Fluent
import Vapor

final class EventApplicantsPivot: Model {
    static let schema = "event_applicants_pivot"
    @ID
    var id: UUID?
    @Parent(key: "event_id")
    var event: Event
    @Parent(key: "user_id")
    var user: User
    init() {}
    init(id: UUID? = nil, event: Event, user: User) throws {
        self.id = id
        self.$event.id = try event.requireID()
        self.$user.id = try user.requireID()
    }
}
