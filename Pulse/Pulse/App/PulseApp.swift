//  PulseApp.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        || ProcessInfo.processInfo.arguments.contains("-UITestMode")
    }

    private var isRemotePushEnabled: Bool {
        Bundle.main.object(forInfoDictionaryKey: "ENABLE_PUSH_NOTIFICATIONS") as? Bool ?? false
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        if isRunningTests {
            configureFirebaseForTests()
            return true
        }

        FirebaseApp.configure()

        guard isRemotePushEnabled else {
            print("DEBUG: Remote push notifications are disabled by configuration.")
            return true
        }

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        Task {
            await NotificationService.shared.requestAuthorizationIfNeeded()
        }

        return true
    }

    private func configureFirebaseForTests() {
        guard FirebaseApp.app() == nil else { return }

        let options = FirebaseOptions(
            googleAppID: "1:1234567890:ios:abcdef123456",
            gcmSenderID: "1234567890"
        )
        options.apiKey = "A12345678901234567890123456789012345678"
        options.projectID = "pulse-tests"
        options.bundleID = Bundle.main.bundleIdentifier ?? "makesspence.Pulse"

        FirebaseApp.configure(options: options)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard isRemotePushEnabled else { return }
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard isRemotePushEnabled else { return }
        guard let fcmToken else { return }
        Task {
            await NotificationService.shared.updateFCMToken(fcmToken)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }
}

@main
struct PulseApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.preferredColorScheme)
        }
    }
}
