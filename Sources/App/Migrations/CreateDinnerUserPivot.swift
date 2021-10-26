//
//  CreateDinnerUserPivot.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 16..
//

import Fluent
import Vapor

struct CreateDinnerInviteePivotMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(DinnerInviteePivot.schema)
            .id()
            .field("invitee_id", .uuid, .references("users", "id"))
            .field("dinner_id", .uuid, .references("dinners", "id"))
            .unique(on: "invitee_id", "dinner_id")
            .create()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(DinnerInviteePivot.schema).delete()
    }
}
