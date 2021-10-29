//
//  CreateEventWorkersPivot.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 29..
//

import Foundation
import Fluent

struct CreateEventWorkersPivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("event_workers_pivot")
            .id()
            .field("event_id", .uuid, .required,
                   .references("events", "id", onDelete: .cascade))
            .field("user_id", .uuid, .required,
                   .references("users", "id", onDelete: .cascade))
            .create()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("event_workers_pivot").delete()
    }
}
