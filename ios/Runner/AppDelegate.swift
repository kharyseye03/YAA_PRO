import Flutter
import GoogleMaps
import GoogleNavigation
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Clé « YAA-DELIVERY iOS », restreinte au bundle gn.yaa.pro et aux
  /// SDK Maps/Navigation iOS. Elle est embarquée dans le binaire : c'est
  /// la restriction côté Google Cloud qui la protège, pas le secret.
  private static let mapsApiKey = "AIzaSyB8L6HE0TRxs2dEXUo1dmRZt3YkN6e33mo"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey(AppDelegate.mapsApiKey)

    // Notifications : flutter_local_notifications a besoin que
    // quelqu'un soit délégué du centre de notifications pour afficher
    // une bannière alors que l'app est déjà au premier plan — iOS ne le
    // fait pas de lui-même. On l'installe **avant** l'enregistrement
    // des greffons, pour que firebase_messaging puisse ensuite passer
    // devant et relayer ce qu'il doit relayer.
    UNUserNotificationCenter.current().delegate = self

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
