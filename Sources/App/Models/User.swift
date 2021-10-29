//
//  User.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 15..
//

import Fluent
import Vapor

enum SCHgroup: String, Codable {
    case sir
    case nyuszi
    case ttny
    case drwu
    case fekete
}

enum Roles: String, Codable {
    case user
    case admin
}

final class User {
    struct Public: Content {
        let username: String
        let id: UUID
        let fullname: String
        let nickname: String?
        let schgroup: SCHgroup?
        let roles: [Roles]
        let createdAt: Date?
        let updatedAt: Date?
    }
    static let schema = "users"
    @ID(key: .id)
    var id: UUID?
    @Field(key: "username")
    var username: String
    @Field(key: "password_hash")
    var passwordHash: String
    @Field(key: "fullname")
    var fullname: String
    @OptionalField(key: "nickname")
    var nickname: String?
    @OptionalEnum(key: "schgroup")
    var schgroup: SCHgroup?
    @Field(key: "roles")
    var roles: [Roles]
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    init() {}
    init(id: UUID? = nil, username: String, passwordHash: String, fullname: String, nickname: String?, schgroup: SCHgroup?, roles: [Roles]) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.fullname = fullname
        self.nickname = nickname
        self.schgroup = schgroup
        self.roles = roles
    }
    static func create(from userSignup: UserSignup) throws -> User {
        let roles: [Roles] = [.user]
        return User(username: userSignup.username,
                    passwordHash: try Bcrypt.hash(userSignup.password),
                    fullname: userSignup.fullname,
                    nickname: userSignup.nickname,
                    schgroup: userSignup.schgroup,
                    roles: roles)
        
    }
    func createToken(source: SessionSource) throws -> Token {
        let calendar = Calendar(identifier: .gregorian)
        let expiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
        return try Token(userId: requireID(),
                         token: [UInt8].random(count: 16).base64, source: source,
                         expiresAt: expiryDate)
    }
    func asPublic() throws -> Public {
        Public(username: username,
               id: try requireID(),
               fullname: fullname,
               nickname: nickname,
               schgroup: schgroup,
               roles: roles,
               createdAt: createdAt,
               updatedAt: updatedAt)
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$passwordHash
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User: ModelSessionAuthenticatable {}
