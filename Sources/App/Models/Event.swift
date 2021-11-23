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
    struct Public: Content {
        var id: UUID?
        var organizer: User.IDValue
        var title: String
        var description: String
        var startDate: Double
        var endDate: Double
        var location: String
        var isApplyable: Bool
        var applicationStart: Double?
        var applicationEnd: Double?
        var parentEvent: Event.IDValue?
    }
    static let schema = "events"
    @ID
    var id: UUID?
    @Parent(key: "organizer")
    var organizer: User
    @Field(key: "title")
    var title: String
    @OptionalField(key: "image")
    var image: String?
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
    @OptionalParent(key: "parent_event")
    var parentEvent: Event?
    @Children(for: \.$parentEvent)
    var subEvents: [Event]
    init() {}
    init(id: UUID? = nil,
         organizer: User.IDValue,
         title: String,
         description: String,
         startDate: Date,
         endDate: Date,
         location: String,
         isApplyable: Bool,
         applicationStart: Date? = nil,
         applicationEnd: Date? = nil,
         parentEvent: Event.IDValue?) {
        self.id = id
        self.$organizer.id = organizer
        self.title = title
        self.image = "default.jpg"
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.isApplyable = isApplyable
        self.applicationStart = applicationStart
        self.applicationEnd = applicationEnd
        self.$parentEvent.id = parentEvent
    }
    static func create(from newEvent: NewEvent, organizer: User.IDValue) throws -> Event {
        Event(organizer: organizer,
              title: newEvent.title,
              description: newEvent.description,
              startDate: Date(timeIntervalSince1970: newEvent.startDate),
              endDate: Date(timeIntervalSince1970: newEvent.endDate),
              location: newEvent.location,
              isApplyable: false,
              applicationStart: nil,
              applicationEnd: nil,
              parentEvent: nil)
    }
}

extension Event {
  func asPublic() -> Event.Public {
      Public(id: id,
             organizer: $organizer.id,
             title: title,
             description: description,
             startDate: startDate.timeIntervalSince1970,
             endDate: endDate.timeIntervalSince1970,
             location: location,
             isApplyable: isApplyable,
             applicationStart: applicationStart?.timeIntervalSince1970,
             applicationEnd: applicationEnd?.timeIntervalSince1970,
             parentEvent: $parentEvent.id)
  }
    func isMain() -> Bool {
        return self.$parentEvent.id == nil
    }
}

extension EventLoopFuture where Value: Event {
    func asPublic() throws -> EventLoopFuture<Event.Public> {
        self.map { $0.asPublic() }
    }
}

extension Collection where Element: Event {
    func asPublic() -> [Event.Public] {
        self.map { $0.asPublic() }
    }
    func onlyMainEvents() -> [Event] {
        self.filter { $0.isMain() }
    }
}

extension EventLoopFuture where Value == Array<Event> {
    func asPublic() -> EventLoopFuture<[Event.Public]> {
        self.map { $0.asPublic() }
    }
}
