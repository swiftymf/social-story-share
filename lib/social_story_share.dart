import 'social_story_share_platform_interface.dart';

/// Entry point for sharing an image to Instagram Stories or Facebook Stories.
class SocialStoryShare {
  /// Scaffolded by `flutter create --template=plugin`. Kept so the generated
  /// example app and tests still compile; safe to remove once the example
  /// targets the real API.
  Future<String?> getPlatformVersion() {
    return SocialStorySharePlatform.instance.getPlatformVersion();
  }

  /// Returns true if Instagram is installed and reachable from this app.
  ///
  /// iOS requires `instagram-stories` (and ideally `instagram`) in the host
  /// app's `LSApplicationQueriesSchemes`. Android requires the Instagram
  /// package in a `<queries>` block; this plugin's AndroidManifest declares
  /// it for you.
  Future<bool> isInstagramInstalled() {
    return SocialStorySharePlatform.instance.isInstagramInstalled();
  }

  /// Shares [imagePath] to the Instagram Stories composer as the background
  /// image. This is image-only sharing — Meta's public Sharing-to-Stories API
  /// does not support injecting tap-through link stickers from third-party
  /// apps.
  ///
  /// [facebookAppId] is optional. Instagram requires a non-empty
  /// `source_application` value in the deep link or it rejects the share with
  /// "The app you shared from doesn't currently support sharing to Stories."
  /// If you have a registered Meta Facebook App ID you can pass it here for
  /// attribution; otherwise the plugin falls back to the host app's
  /// bundle ID / package name, which Instagram also accepts.
  ///
  /// Returns true if the share intent was dispatched.
  Future<bool> shareToInstagramStory({
    required String imagePath,
    String? facebookAppId,
  }) {
    return SocialStorySharePlatform.instance.shareToInstagramStory(
      imagePath: imagePath,
      facebookAppId: facebookAppId,
    );
  }

  /// Returns true if Facebook is installed and reachable from this app.
  ///
  /// iOS requires `facebook-stories` (and ideally `facebook`) in the host
  /// app's `LSApplicationQueriesSchemes`. Android requires the Facebook
  /// package in a `<queries>` block; this plugin's AndroidManifest declares
  /// it for you.
  Future<bool> isFacebookInstalled() {
    return SocialStorySharePlatform.instance.isFacebookInstalled();
  }

  /// Shares [imagePath] to the Facebook Stories composer as the background
  /// image.
  ///
  /// Unlike Instagram, Facebook validates [facebookAppId] against Meta's
  /// registry and rejects unknown values, so a real, registered Facebook
  /// App ID is required — there is no usable bundle-ID fallback. Pass the
  /// numeric ID from Settings → Basic at developers.facebook.com.
  ///
  /// Facebook Stories has the same restricted Link-sticker API as Instagram,
  /// so this method only ships the visual background. No tappable link.
  ///
  /// Returns true if the share intent was dispatched.
  Future<bool> shareToFacebookStory({
    required String imagePath,
    required String facebookAppId,
  }) {
    return SocialStorySharePlatform.instance.shareToFacebookStory(
      imagePath: imagePath,
      facebookAppId: facebookAppId,
    );
  }
}
