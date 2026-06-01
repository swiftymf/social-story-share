import Flutter
import UIKit

public class SocialStorySharePlugin: NSObject, FlutterPlugin {
  // Standard Instagram pasteboard keys. Documented by Meta for the public
  // "Sharing to Stories" iOS integration.
  private static let kInstagramBackgroundImage = "com.instagram.sharedSticker.backgroundImage"

  // Standard Facebook pasteboard keys. Documented by Meta for the public
  // "Sharing to Stories" iOS integration.
  private static let kFacebookBackgroundImage = "com.facebook.sharedSticker.backgroundImage"
  private static let kFacebookAppID = "com.facebook.sharedSticker.appID"

  // Pasteboard expiration window. Long enough for Instagram to consume the
  // sticker payload but short enough that we don't pollute the user's
  // clipboard indefinitely if Instagram never opens.
  private static let kPasteboardExpiration: TimeInterval = 60 * 5

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "social_story_share",
      binaryMessenger: registrar.messenger()
    )
    let instance = SocialStorySharePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "isInstagramInstalled":
      result(isInstagramInstalled())
    case "shareToInstagramStory":
      shareToInstagramStory(call: call, result: result)
    case "isFacebookInstalled":
      result(isFacebookInstalled())
    case "shareToFacebookStory":
      shareToFacebookStory(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func isInstagramInstalled() -> Bool {
    guard let url = URL(string: "instagram-stories://share") else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  private func shareToInstagramStory(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let args = call.arguments as? [String: Any],
          let imagePath = args["imagePath"] as? String
    else {
      result(
        FlutterError(
          code: "INVALID_ARGS",
          message: "imagePath is required.",
          details: nil
        )
      )
      return
    }

    // Instagram's deep link requires a non-empty source_application — without
    // one, Instagram rejects the share with "The app you shared from doesn't
    // currently support sharing to Stories." A real Facebook App ID enables
    // attribution features, but any non-empty value satisfies the basic check.
    // If the caller didn't provide one, fall back to the host app's bundle
    // identifier (which is always real and always non-empty).
    let sourceApplication: String =
      (args["facebookAppId"] as? String).flatMap {
        $0.isEmpty ? nil : $0
      } ?? Bundle.main.bundleIdentifier ?? "unknown"

    guard let backgroundImage = UIImage(contentsOfFile: imagePath)
    else {
      result(
        FlutterError(
          code: "IMAGE_READ_FAILED",
          message: "Could not load a UIImage from \(imagePath).",
          details: nil
        )
      )
      return
    }

    guard let instagramURL = URL(
      string: "instagram-stories://share?source_application=\(sourceApplication)"
    ),
          UIApplication.shared.canOpenURL(instagramURL)
    else {
      result(
        FlutterError(
          code: "INSTAGRAM_UNAVAILABLE",
          message: "Instagram is not installed or the deep link is unavailable.",
          details: nil
        )
      )
      return
    }

    let stickerItem: [String: Any] = [
      SocialStorySharePlugin.kInstagramBackgroundImage: backgroundImage
    ]
    let options: [UIPasteboard.OptionsKey: Any] = [
      .expirationDate: Date(
        timeIntervalSinceNow: SocialStorySharePlugin.kPasteboardExpiration
      )
    ]
    UIPasteboard.general.setItems([stickerItem], options: options)

    UIApplication.shared.open(instagramURL, options: [:]) { opened in
      result(opened)
    }
  }

  private func isFacebookInstalled() -> Bool {
    guard let url = URL(string: "facebook-stories://share") else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  private func shareToFacebookStory(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let args = call.arguments as? [String: Any],
          let imagePath = args["imagePath"] as? String
    else {
      result(
        FlutterError(
          code: "INVALID_ARGS",
          message: "imagePath is required.",
          details: nil
        )
      )
      return
    }

    // Facebook validates source_application against Meta's registry — unknown
    // values get rejected with "doesn't currently support sharing to Stories,"
    // so unlike Instagram we cannot fall back to the bundle ID. The caller
    // must supply a real, registered Facebook App ID.
    guard let facebookAppId = (args["facebookAppId"] as? String)
      .flatMap({ $0.isEmpty ? nil : $0 })
    else {
      result(
        FlutterError(
          code: "INVALID_ARGS",
          message:
            "facebookAppId is required for Facebook Stories. Facebook "
            + "validates this against its registered apps; there is no "
            + "bundle-ID fallback.",
          details: nil
        )
      )
      return
    }

    guard let backgroundImage = UIImage(contentsOfFile: imagePath)
    else {
      result(
        FlutterError(
          code: "IMAGE_READ_FAILED",
          message: "Could not load a UIImage from \(imagePath).",
          details: nil
        )
      )
      return
    }

    // Meta's iOS contract uses a bare facebook-stories://share URL and passes the
    // App ID on the pasteboard (com.facebook.sharedSticker.appID), not only in
    // the query string. Without the pasteboard appID key, Facebook often opens
    // to the home feed instead of the Stories composer.
    guard let facebookURL = URL(string: "facebook-stories://share"),
          UIApplication.shared.canOpenURL(facebookURL)
    else {
      result(
        FlutterError(
          code: "FACEBOOK_UNAVAILABLE",
          message: "Facebook is not installed or the deep link is unavailable.",
          details: nil
        )
      )
      return
    }

    let item: [String: Any] = [
      SocialStorySharePlugin.kFacebookBackgroundImage: backgroundImage,
      SocialStorySharePlugin.kFacebookAppID: facebookAppId,
    ]
    let options: [UIPasteboard.OptionsKey: Any] = [
      .expirationDate: Date(
        timeIntervalSinceNow: SocialStorySharePlugin.kPasteboardExpiration
      )
    ]
    UIPasteboard.general.setItems([item], options: options)

    UIApplication.shared.open(facebookURL, options: [:]) { opened in
      result(opened)
    }
  }
}
