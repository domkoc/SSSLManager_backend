//
//  CreateSubEventPivot.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 29..
//

import Foundation
import Fluent

struct CreateSubEventPivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("sub_event_pivot")
            .id()
            .field("event_id", .uuid, .required,
                   .references("events", "id", onDelete: .cascade))
            .field("sub_event_id", .uuid, .required,
                   .references("events", "id", onDelete: .cascade))
            .create()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("sub_event_pivot").delete()
    }
}
