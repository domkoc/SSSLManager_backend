//
//  Event.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 29..
//

import Foundation
import Fluent
import Vapor

final class Event: Model, Content {
    static let schema = "events"
    @ID
    var id: UUID?
    @Parent(key: "organizer")
    var organizer: User
    @Field(key: "title")
    var title: String
    @Field(key: "description")
    var description: String
    @Field(key: "start_date")
    var startDate: Date
    @Field(key: "end_date")
    var endDate: Date
    @Field(key: "location")
    var location: String
    @Field(key: "is_applyable")
    var isApplyable: Bool
    @OptionalField(key: "application_start")
    var applicationStart: Date?
    @OptionalField(key: "application_end")
    var applicationEnd: Date?
    @Siblings(through: EventApplicantsPivot.self,
              from: \.$event,
              to: \.$user)
    var applicants: [User]
    @Siblings(through: EventWorkersPivot.self,
              from: \.$event,
              to: \.$user)
    var workers: [User]
    @Siblings(through: SubEventPivot.self,
              from: \.$event,
              to: \.$subEvent)
    var SubEvents: [Event]
    
    init() {}
}
