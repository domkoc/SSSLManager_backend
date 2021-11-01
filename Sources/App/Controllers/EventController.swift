//
//  EventController.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 30..
//

import Fluent
import Vapor

struct NewEvent: Content {
        var title: String
        var description: String
        var startDate: Double
        var endDate: Double
        var location: String
}

extension NewEvent: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: !.empty)
        validations.add("description", as: String.self)
        validations.add("startDate", as: Double.self)
        validations.add("endDate", as: Double.self)
        validations.add("location", as: String.self)
    }
}

struct EventController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let eventsRoute = routes.grouped("events")
            .grouped(Token.authenticator())
        eventsRoute.post("new", use: create)
        eventsRoute.get("all", use: getAll)
    }
    fileprivate func getAll(req: Request) -> EventLoopFuture<[Event.Public]> {
        Event.query(on: req.db).all().asPublic()
    }
    fileprivate func create(req: Request) throws -> EventLoopFuture<Event.Public> {
        let user = try req.auth.require(User.self)
        try NewEvent.validate(content: req)
        let newEvent = try req.content.decode(NewEvent.self)
        let event = try Event.create(from: newEvent, organizer: user.requireID())
        return checkIfExists(event.title, req: req).flatMap { exists in
            guard !exists else {
                return req.eventLoop.future(error: EventError.eventTitleTaken)
            }
            return event.save(on: req.db)
        }.flatMap {
            req.eventLoop.future(event.asPublic())
        }
    }
    private func checkIfExists(_ eventTitle: String, req: Request) -> EventLoopFuture<Bool> {
        Event.query(on: req.db)
            .filter(\.$title == eventTitle)
            .first()
            .map { $0 != nil }
    }
}
