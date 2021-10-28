import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: UserController())
    try app.register(collection: DinnerController())
    try app.register(collection: TodoController())
    try app.register(collection: ImperialController())
}
