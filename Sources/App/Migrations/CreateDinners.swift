//
//  CreateDinners.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 16..
//

import Fluent

struct CreateDinners: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Dinner.schema)
            .id()
            .field("date", .datetime, .required)
            .field("host_id", .uuid, .references("users", "id"), .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .field("location", .string, .required)
            .create()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Dinner.schema).delete()
    }
}
