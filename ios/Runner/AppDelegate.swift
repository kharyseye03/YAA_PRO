import Flutter
import GoogleMaps
import GoogleNavigation
import UIKit

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
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
