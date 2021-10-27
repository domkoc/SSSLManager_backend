//
//  UserController.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 16..
//

import Vapor
import Fluent

struct UserSignup: Content {
    let username: String
    let password: String
    let fullname: String
    let nickname: String?
    let schgroup: SCHgroup
}

struct NewSession: Content {
    let token: String
    let user: User.Public
}

extension UserSignup: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("username", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(6...))
        validations.add("fullname", as: String.self, is: !.empty)
        validations.add("schgroup", as: SCHgroup.self)
    }
}
struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("users")
        usersRoute.post("signup", use: create)
        let tokenProtected = usersRoute.grouped(Token.authenticator())
        tokenProtected.get("me", use: getMyOwnUser)
        tokenProtected.post("logout", use: logout)
        tokenProtected.put("update", use: update)
        let passwordProtected = usersRoute.grouped(User.authenticator())
        passwordProtected.post("login", use: login)
    }
    fileprivate func create(req: Request) throws -> EventLoopFuture<NewSession> {
        try UserSignup.validate(content: req)
        let userSignup = try req.content.decode(UserSignup.self)
        let user = try User.create(from: userSignup)
        var token: Token!
        return checkIfUserExists(userSignup.username, req: req).flatMap { exists in
            guard !exists else {
                return req.eventLoop.future(error: UserError.usernameTaken)
            }
            
            return user.save(on: req.db)
        }.flatMap {
            guard let newToken = try? user.createToken(source: .signup) else {
                return req.eventLoop.future(error: Abort(.internalServerError))
            }
            token = newToken
            return token.save(on: req.db)
        }.flatMapThrowing {
            NewSession(token: token.value, user: try user.asPublic())
        }
    }
    fileprivate func login(req: Request) throws -> EventLoopFuture<NewSession> {
        let user = try req.auth.require(User.self)
        let token = try user.createToken(source: .login)
        return token
            .save(on: req.db)
            .flatMapThrowing {
                NewSession(token: token.value, user: try user.asPublic())
            }
    }
    func getMyOwnUser(req: Request) throws -> User.Public {
        try req.auth.require(User.self).asPublic()
    }
    fileprivate func logout(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let tokenString = req.headers.bearerAuthorization?.token else {
            return req.eventLoop.future(HTTPStatus.notFound)
        }
        return Token.query(on: req.db)
            .filter(\.$value == tokenString)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { token in
                token.delete(on: req.db).transform(to: .noContent)
            }
    }
    fileprivate func update(req: Request) throws -> EventLoopFuture<User.Public> {
            //let user = try req.auth.require(User.self) // TODO: Itt tartok
        throw Abort(.notImplemented)
    }
    private func checkIfUserExists(_ username: String, req: Request) -> EventLoopFuture<Bool> {
        User.query(on: req.db)
            .filter(\.$username == username)
            .first()
            .map { $0 != nil }
    }
}
