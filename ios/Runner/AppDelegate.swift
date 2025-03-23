import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 使用主线程安全延迟初始化以避免Swift/Obj-C混合环境下的崩溃
    DispatchQueue.main.async {
      self.initializePlugins()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func initializePlugins() {
    do {
      if let registry = self as? FlutterPluginRegistry {
        GeneratedPluginRegistrant.register(with: registry)
      }
    } catch {
      print("插件注册过程中出错: \(error)")
    }
  }
}
