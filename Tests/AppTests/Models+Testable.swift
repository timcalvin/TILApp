//
//  File.swift
//
//
//  Created by Tim Bryant on 6/24/24.
//
//
//import App
//import XCTVapor
//
//extension Application {
//    var app: Application!
//    
//    override func setUp() async throws {
//        self.app = try await Application.make(.testing)
//        try await configure(app)
//        try await app.autoMigrate()
//    }
//    
//    override func tearDown() async throws {
//        try await app.autoRevert()
//        try await self.app.asyncShutdown()
//        self.app = nil
//    }
//}
