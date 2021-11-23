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

struct EventApplicationState: Content {
    var didApply: Bool
}

struct NewEventImageUpload: Content {
    let image: Data
}

struct EventController: RouteCollection {
    let imageFolder = "EventPictures/"
    func boot(routes: RoutesBuilder) throws {
        let eventsRoute = routes.grouped("events")
            .grouped(Token.authenticator())
        eventsRoute.post("new", use: create)
        eventsRoute.get("all", use: getAll)
        eventsRoute.get(":eventID", use: getEventById)
        eventsRoute.get(":eventID", "apply", use: getApplyedToEvent)
        eventsRoute.post(":eventID", "apply", use: applyOrUnapplyToEvent)
//        eventsRoute.post(":eventID", "apply", use: applyToEvent)
//        eventsRoute.delete(":eventID", "apply", use: deleteApplicationToEvent)
        eventsRoute.post(":eventID", "apply", "toggle", use: toggleApplyability)
        eventsRoute.post(":eventID", "accept", ":userID", use: acceptApplicant)
        eventsRoute.post(":eventID", "addSubEvent", use: addSubEvent)
        eventsRoute.put(":eventID", "image", use: uploadEventImage)
        eventsRoute.on(.POST, ":eventID", "image", body: .collect(maxSize: "10mb"), use: uploadEventImage)
        eventsRoute.get(":eventID", "image", use: getEventPicture)
        eventsRoute.get(":eventID", "subEvents", use: getSubEventsByEventId)
        eventsRoute.get(":eventID", "applicants", use: getApplicantsByEventId)
        eventsRoute.get(":eventID", "workers", use: getWorkersByEventId)
    }
    fileprivate func getAll(req: Request) -> EventLoopFuture<[Event.Public]> {
        Event.query(on: req.db)
            .sort(\.$startDate)
            .all()
            .map { $0.onlyMainEvents().asPublic() }
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
    fileprivate func getEventById(req: Request) throws -> EventLoopFuture<Event.Public> {
        try Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .asPublic()
    }
    fileprivate func getApplyedToEvent(req: Request) throws -> EventLoopFuture<EventApplicationState> {
        let user = try req.auth.require(User.self)
        return Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { event in
                event.$applicants.get(on: req.db)
                    .map { applicants in
                        EventApplicationState(didApply: applicants.contains(where: { $0.id == user.id }))
                }
            }
    }
    fileprivate func applyOrUnapplyToEvent(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        return Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { event in
                event.$applicants.get(on: req.db)
                    .flatMap { applicants in
                        if applicants.contains(where: { $0.id == user.id }) {
                            if event.isApplyable {
                                return event.$applicants.detach(user, on: req.db).transform(to: .accepted)
                            } else {
                                return req.eventLoop.future(error: EventError.notApplyable)
                            }
                        } else {
                            if event.isApplyable {
                                return event.$applicants.attach(user, on: req.db).transform(to: .accepted)
                            } else {
                                return req.eventLoop.future(error: EventError.notApplyable)
                            }
                        }
                }
            }
    }
    fileprivate func toggleApplyability(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        return Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { event in
                if user.id != event.$organizer.id {
                    return req.eventLoop.future(HTTPStatus.unauthorized)
                } else {
                    event.isApplyable.toggle()
                    return event.save(on: req.db).map {
                        return HTTPStatus.ok
                    }
                }
            }
    }
    fileprivate func applyToEvent(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        return Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { event in
                if event.isApplyable {
                    return event.$applicants.attach(user, on: req.db).transform(to: .accepted)
                } else {
                    return req.eventLoop.future(error: EventError.notApplyable)
                }
            }
    }
    fileprivate func deleteApplicationToEvent(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        return Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { event in
                if event.isApplyable {
                    return event.$applicants.detach(user, on: req.db).transform(to: .accepted)
                } else {
                    return req.eventLoop.future(error: EventError.notApplyable)
                }
            }
    }
    fileprivate func acceptApplicant(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let authUser = try req.auth.require(User.self)
        let eventQuery = Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return eventQuery.and(userQuery).flatMap { event, user in
            if event.$organizer.id != authUser.id {
                return req.eventLoop.future(.forbidden)
            } else {
                let detachQuery = event.$applicants.detach(user, on: req.db)
                let attachQuery = event.$workers.attach(user, on: req.db)
                return detachQuery.and(attachQuery).map { _ in
                        .accepted
                }
            }
        }
    }
    fileprivate func addSubEvent(req: Request) throws -> EventLoopFuture<Event.Public> {
        let user = try req.auth.require(User.self)
        try NewEvent.validate(content: req)
        let newEvent = try req.content.decode(NewEvent.self)
        let mainEventQuery = Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let event = try Event.create(from: newEvent, organizer: user.requireID())
        return checkIfExists(event.title, req: req)
            .and(mainEventQuery).flatMap { exists, mainEvent in
            guard !exists else {
                return req.eventLoop.future(error: EventError.eventTitleTaken)
            }
            event.$parentEvent.id = mainEvent.id
            return event.save(on: req.db)
        }.flatMap {
            req.eventLoop.future(event.asPublic())
        }
    }
    fileprivate func uploadEventImage(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let loggedInUser = try req.auth.require(User.self)
        let newEventImageUpload = try req.content.decode(NewEventImageUpload.self)
        return Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { event in
                if event.$organizer.id != loggedInUser.id {
                    return req.eventLoop.future(.forbidden)
                } else {
                    let name = "\(event.id!.uuidString)-\(UUID()).jpg"
                    let path = req.application.directory.workingDirectory + imageFolder + name
                    return req.fileio
                        .writeFile(.init(data: newEventImageUpload.image), at: path)
                        .flatMap {
                            event.image = name
                            return event.save(on: req.db).map {
                                HTTPStatus.ok
                            }
                        }
                }
            }
    }
    fileprivate func getEventPicture(req: Request) throws -> EventLoopFuture<Response> {
        Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { event in
                guard let filename = event.image else {
                    throw Abort(.notFound)
                }
                let path = req.application.directory.workingDirectory + imageFolder + filename
                return req.fileio.streamFile(at: path)
            }
    }
    fileprivate func getSubEventsByEventId(req: Request) -> EventLoopFuture<[Event.Public]> {
        Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { event in
                event.$subEvents.get(on: req.db).asPublic()
              }
    }
    fileprivate func getApplicantsByEventId(req: Request) -> EventLoopFuture<[User.Public]> {
        Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { event in
                event.$applicants.get(on: req.db).asPublic()
              }
    }
    fileprivate func getWorkersByEventId(req: Request) -> EventLoopFuture<[User.Public]> {
        Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { event in
                event.$workers.get(on: req.db).asPublic()
              }
    }
    private func checkIfExists(_ eventTitle: String, req: Request) -> EventLoopFuture<Bool> {
        Event.query(on: req.db)
            .filter(\.$title == eventTitle)
            .first()
            .map { $0 != nil }
    }
}
