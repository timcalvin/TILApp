//
//  UserTests.swift
//
//
//  Created by Tim Bryant on 6/24/24.
//

@testable import App
import XCTVapor
import Fluent

final class UserTests: XCTestCase {
    var app: Application!
    
    let usersName = "Alice"
    let usersUsername = "alice"
    let usersURI = "api/users/"
    
    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)
        try await app.autoMigrate()
    }
    
    override func tearDown() async throws {
        try await app.autoRevert()
        try await self.app.asyncShutdown()
        self.app = nil
    }
    
    func testUsersCanBeRetrievedFromAPI() async throws {
        let user = try await User.create(name: usersName, username: usersUsername, on: app.db)
        _ = try await User.create(on: app.db)
        
        try await app.test(.GET, usersURI) { response async in
            XCTAssertEqual(response.status, .ok)
            do {
                let users = try response.content.decode([User].self)
                
                XCTAssertEqual(users.count, 2)
                XCTAssertEqual(users[0].name, usersName)
                XCTAssertEqual(users[0].username, usersUsername)
                XCTAssertEqual(users[0].id, user.id)
            } catch {
                print("Failed to decode users")
            }
        }
    }
    
    func testUserCanBeSavedWithAPI() async throws {
        let user = User(name: usersName, username: usersUsername)
        
        try await app.test(.POST, usersURI, beforeRequest: { req in
            try req.content.encode(user)
        }, afterResponse: { response async throws in
            let receivedUser = try response.content.decode(User.self)
            
            XCTAssertEqual(receivedUser.name, usersName)
            XCTAssertEqual(receivedUser.username, usersUsername)
            XCTAssertNotNil(receivedUser.id)
            
            try await app.test(.GET, usersURI) { secondResponse in
                let users = try secondResponse.content.decode([User].self)
                
                XCTAssertEqual(users.count, 1)
                XCTAssertEqual(users[0].name, usersName)
                XCTAssertEqual(users[0].username, usersUsername)
                XCTAssertEqual(users[0].id, receivedUser.id)
            }
        })
    }
    
    func testGettingASingleUserFromTheAPI() async throws {
        let user = try await User.create(name: usersName, username: usersUsername, on: app.db)
        
        try await app.test(.GET, "\(usersURI)\(user.id!)") { response in
            let receivedUser = try response.content.decode(User.self)
            
            XCTAssertEqual(receivedUser.name, usersName)
            XCTAssertEqual(receivedUser.username, usersUsername)
            XCTAssertEqual(receivedUser.id, user.id)
        }
    }
    
    func testGettingAUsersAcronymsFromTheAPI() async throws {
        let user = try await User.create(on: app.db)
        
        let acronymShort = "OMG"
        let acronymLong = "Oh My God"
        
        let acronym1 = try await Acronym.create( short: acronymShort, long: acronymLong, user: user, on: app.db)
        _ = try await Acronym.create(short: "LOL", long: "Laugh Out Loud", user: user, on: app.db)
        
        try await app.test(.GET, "\(usersURI)\(user.id!)/acronyms") { response in
            let acronyms = try response.content.decode([Acronym].self)
            
            XCTAssertEqual(acronyms.count, 2)
            XCTAssertEqual(acronyms[0].id, acronym1.id)
            XCTAssertEqual(acronyms[0].short, acronymShort)
            XCTAssertEqual(acronyms[0].long, acronymLong)
        }
    }
}
