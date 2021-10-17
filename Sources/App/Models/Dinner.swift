//
//  Dinner.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 16..
//

import Fluent
import Vapor

final class Dinner: Model, Content {
    struct Public: Content {
        let id: UUID
        let date: Date
        let location: String
        let host: User.Public
        let invitees: [User.Public]
        let createdAt: Date?
        let updatedAt: Date?
    }
    static let schema = "dinners"
    @ID(key: .id)
    var id: UUID?
    @Field(key: "date")
    var date: Date
    @Field(key: "location")
    var location: String
    @Parent(key: "host_id")
    var host: User
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    @Siblings(through: DinnerInviteePivot.self, from: \.$dinner, to: \.$invitee)
    var invitees: [User]
    init() {}
    init(id: UUID? = nil, date: Date, location: String, hostId: User.IDValue) {
        self.id = id
        self.date = date
        self.$host.id = hostId
        self.location = location
    }
}

extension Dinner {
    func asPublic() throws -> Public {
        Public(id: try requireID(),
               date: date,
               location: location,
               host: try host.asPublic(),
               invitees: try invitees.map { try $0.asPublic() },
               createdAt: createdAt,
               updatedAt: updatedAt)
    }
}
