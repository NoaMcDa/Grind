import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Notification actions without the foreground option (Done, Snooze) run
    // Dart in a background isolate. That isolate needs the plugins
    // registered so it can reach path_provider and write the response
    // journal. See docs/adr/0003-notifications.md.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // FlutterAppDelegate forwards UNUserNotificationCenterDelegate calls to
    // plugins; flutter_local_notifications needs it to be the delegate to
    // present notifications in the foreground and receive action taps.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
