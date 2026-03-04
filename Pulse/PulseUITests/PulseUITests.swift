//
//  PulseUITests.swift
//  PulseUITests
//
//  Created by Codex on 2/18/26.
//

import XCTest

final class PulseUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunches() {
        let app = XCUIApplication()
        app.launchArguments.append("-UITestMode")
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    func testPrimaryRouteIsVisible() {
        let app = XCUIApplication()
        app.launchArguments.append("-UITestMode")
        app.launch()

        let loginVisible = app.buttons["login.submit"].waitForExistence(timeout: 5)
        let tabBarVisible = app.tabBars.firstMatch.waitForExistence(timeout: 5)

        XCTAssertTrue(loginVisible || tabBarVisible)
    }

    func testSignInScreenShowsPrimaryControls() {
        let app = makeApp(extraArguments: ["-UITest_ForceLoggedOut"])
        app.launch()

        XCTAssertTrue(app.textFields["login.email"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.secureTextFields["login.password"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["login.submit"].waitForExistence(timeout: 5))
    }

    func testCreatePostComposerShowsTextImageAndVoiceControls() {
        let app = makeApp(extraArguments: ["-UITest_ShowFeed"])
        app.launch()

        app.tabBars.buttons["Post"].tap()

        XCTAssertTrue(app.otherElements["createThread.view"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["createThread.caption"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["createThread.photo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["createThread.voice"].waitForExistence(timeout: 5))

        let captionField = app.descendants(matching: .any)["createThread.caption"]
        captionField.tap()
        captionField.typeText("Queued sync test")

        XCTAssertTrue(app.buttons["createThread.submit"].exists)
    }

    func testCanToggleFollowFromDiscover() {
        let app = makeApp(extraArguments: ["-UITest_ShowFeed"])
        app.launch()

        app.tabBars.buttons["People"].tap()

        let followButton = app.buttons["Follow"].firstMatch
        XCTAssertTrue(followButton.waitForExistence(timeout: 5))

        followButton.tap()

        XCTAssertTrue(app.buttons["Following"].firstMatch.waitForExistence(timeout: 5))
    }

    func testActivityTabOpensAndShowsNotificationsSurface() {
        let app = makeApp(extraArguments: ["-UITest_ShowFeed"])
        app.launch()

        app.tabBars.buttons["Activity"].tap()

        XCTAssertTrue(app.navigationBars["Activity"].waitForExistence(timeout: 5))
    }

    private func makeApp(extraArguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-UITestMode")
        app.launchArguments.append(contentsOf: extraArguments)
        return app
    }
}
