import Flutter
import MediaPlayer
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SonifyStorage") {
      StorageChannel.register(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SonifyNowPlaying") {
      NowPlayingChannel.register(messenger: registrar.messenger())
    }
  }
}

/// Canal `app.sonify.sonify/now_playing` (ver `sonify_audio_handler.dart`).
enum NowPlayingChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "app.sonify.sonify/now_playing", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "renew" else {
        result(FlutterMethodNotImplemented)
        return
      }
      // Si el usuario limpió el reproductor de la pantalla de bloqueo, repetir
      // los mismos datos no lo trae de vuelta: se vuelve a publicar desde cero.
      UIApplication.shared.beginReceivingRemoteControlEvents()
      let center = MPNowPlayingInfoCenter.default()
      let info = center.nowPlayingInfo
      center.nowPlayingInfo = nil
      center.nowPlayingInfo = info
      result(nil)
    }
  }
}

/// Canal `app.sonify.sonify/storage` (ver `device_storage.dart`).
enum StorageChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "app.sonify.sonify/storage", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
        result(FlutterError(code: "bad_args", message: "Falta path", details: nil))
        return
      }
      var url = URL(fileURLWithPath: path)
      switch call.method {
      case "freeBytes":
        // "Important usage": cuenta el espacio que iOS liberaría purgando cachés.
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        result(values?.volumeAvailableCapacityForImportantUsage.map { NSNumber(value: $0) })
      case "excludeFromBackup":
        // Las descargas nunca van a iCloud ni a respaldos del sistema.
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
          try url.setResourceValues(values)
          result(nil)
        } catch {
          result(FlutterError(code: "io", message: error.localizedDescription, details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
