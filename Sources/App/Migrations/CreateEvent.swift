//
//  CreateEvent.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 29..
//

import Foundation
import Fluent

struct CreateEvent: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("events")
            .id()
            .field("title", .string, .required)
            .field("organizer", .uuid, .required,
                    .references("users", "id", onDelete: .cascade))
            .field("image", .string)
            .field("description", .string, .required)
            .field("start_date", .datetime, .required)
            .field("end_date", .datetime, .required)
            .field("location", .string, .required)
            .field("is_applyable", .bool, .required)
            .field("application_start", .datetime)
            .field("application_end", .datetime)
            .field("parent_event", .uuid,
                   .references("events", "id", onDelete: .cascade))
            .create()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("events").delete()
    }
}
