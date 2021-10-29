//
//  SubEventPivot.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 29..
//

import Foundation
import Fluent
import Vapor

final class SubEventPivot: Model {
    static let schema = "sub_event_pivot"
    @ID
    var id: UUID?
    @Parent(key: "event_id")
    var event: Event
    @Parent(key: "sub_event_id")
    var subEvent: Event
    init() {}
    init(id: UUID? = nil, event: Event, subEvent: Event) throws {
        self.id = id
        self.$event.id = try event.requireID()
        self.$subEvent.id = try subEvent.requireID()
    }
}
