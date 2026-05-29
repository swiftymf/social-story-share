import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'social_story_share_method_channel.dart';

abstract class SocialStorySharePlatform extends PlatformInterface {
  SocialStorySharePlatform() : super(token: _token);

  static final Object _token = Object();

  static SocialStorySharePlatform _instance = MethodChannelSocialStoryShare();

  static SocialStorySharePlatform get instance => _instance;

  static set instance(SocialStorySharePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> isInstagramInstalled() {
    throw UnimplementedError(
      'isInstagramInstalled() has not been implemented.',
    );
  }

  Future<bool> shareToInstagramStory({
    required String imagePath,
    String? facebookAppId,
  }) {
    throw UnimplementedError(
      'shareToInstagramStory() has not been implemented.',
    );
  }

  Future<bool> isFacebookInstalled() {
    throw UnimplementedError(
      'isFacebookInstalled() has not been implemented.',
    );
  }

  Future<bool> shareToFacebookStory({
    required String imagePath,
    required String facebookAppId,
  }) {
    throw UnimplementedError(
      'shareToFacebookStory() has not been implemented.',
    );
  }
}
