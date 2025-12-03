import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register streaming plugin
    let controller = window?.rootViewController as! FlutterViewController
    StreamingPlugin.register(with: registrar(forPlugin: "StreamingPlugin")!)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
