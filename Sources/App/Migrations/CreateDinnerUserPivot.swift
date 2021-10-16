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
            .field("id", .int, .identifier(auto: true))
            .field("invitee_id", .int, .references("users", "id"))
            .field("dinner_id", .int, .references("dinners", "id"))
            .unique(on: "invitee_id", "dinner_id")
            .create()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(DinnerInviteePivot.schema).delete()
    }
}
