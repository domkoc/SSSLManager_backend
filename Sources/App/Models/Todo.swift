import Fluent
import Vapor

final class Todo: Model, Content {
    static let schema = "todos"
    
    struct FieldKeys {
        static var title: FieldKey { "title" }
    }
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: FieldKeys.title)
    var title: String

    init() { }

    init(id: UUID? = nil, title: String) {
        self.id = id
        self.title = title
    }
}
