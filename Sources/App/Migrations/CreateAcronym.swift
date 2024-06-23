//
//  CreateAcronym.swift
//
//
//  Created by Tim Bryant on 6/20/24.
//

import Fluent
import Foundation

struct CreateAcronym: Migration {
    func prepare(on database: any FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema("acronyms")
            .id()
            .field("short", .string, .required)
            .field("long", .string, .required)
            .field("userID", .uuid, .required, .references("users", "id"))
            .create()
    }
    
    func revert(on database: any FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema("acronyms").delete()
    }
}
