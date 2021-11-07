//
//  ImperialController.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 27..
//

import ImperialGoogle
import Vapor
import Fluent

struct ImperialController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        guard let googleCallbackURL =
                Environment.get("GOOGLE_CALLBACK_URL") else {
                    fatalError("Google callback URL not set")
                }
        try routes.oAuth(
            from: Google.self,
            authenticate: "login-google",
            callback: googleCallbackURL,
            scope: ["profile", "email"],
            completion: processGoogleLogin)
        routes.get("iOS", "login-google", use: iOSGoogleLogin)
    }
    func processGoogleLogin(request: Request, token: String) throws -> EventLoopFuture<ResponseEncodable> {
        try Google
            .getUser(on: request)
            .flatMap { userInfo in
                User.query(on: request.db)
                    .filter(\.$username == userInfo.email)
                    .first()
                    .flatMap { foundUser in
                        guard let existingUser = foundUser else {
                            do {
                                let user = try User.create(from: UserSignup(username: userInfo.email,
                                                                            password: UUID().uuidString,
                                                                            fullname: userInfo.name,
                                                                            nickname: nil,
                                                                            schgroup: nil))
                                return user.save(on: request.db).flatMap {
                                    request.session.authenticate(user)
                                    return generateRedirect(on: request, for: user)
                                }
                            } catch {
                                return request.eventLoop.future(HTTPStatus.internalServerError)
                            }
                        }
                        request.session.authenticate(existingUser)
                        return generateRedirect(on: request, for: existingUser)
                    }
            }
    }
    func iOSGoogleLogin(_ req: Request) -> Response {
        req.session.data["oauth_login"] = "iOS"
        return req.redirect(to: "/login-google")
    }
    func generateRedirect(on req: Request, for user: User) -> EventLoopFuture<ResponseEncodable> {
        let redirectURL: EventLoopFuture<String>
        if req.session.data["oauth_login"] == "iOS" {
            do {
                let token = try user.createToken(source: .login)
                token.save(on: req.db)
                    .flatMapThrowing {
                        NewSession(token: token.value, user: try user.asPublic(), expiration: token.expiresAt?.timeIntervalSince1970)
                    }
                redirectURL = token.save(on: req.db).map {
                    "ssslmanager://auth?token=\(token.value)"
                }
            } catch {
                return req.eventLoop.future(error: error)
            }
        } else {
            redirectURL = req.eventLoop.future("/")
        }
        req.session.data["oauth_login"] = nil
        return redirectURL.map { url in
            req.redirect(to: url)
        }
    }
    
}

struct GoogleUserInfo: Content {
    let email: String
    let name: String
}

extension Google {
    static func getUser(on request: Request) throws -> EventLoopFuture<GoogleUserInfo> {
        var headers = HTTPHeaders()
        headers.bearerAuthorization =
        try BearerAuthorization(token: request.accessToken())
        let googleAPIURL: URI = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
        return request
            .client
            .get(googleAPIURL, headers: headers)
            .flatMapThrowing { response in
                guard response.status == .ok else {
                    if response.status == .unauthorized {
                        throw Abort.redirect(to: "/login-google")
                    } else {
                        throw Abort(.internalServerError)
                    }
                }
                return try response.content
                    .decode(GoogleUserInfo.self)
            }
    }
}
