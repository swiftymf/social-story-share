import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'social_story_share_platform_interface.dart';

class MethodChannelSocialStoryShare extends SocialStorySharePlatform {
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel(
    'social_story_share',
  );

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<bool> isInstagramInstalled() async {
    final installed = await methodChannel.invokeMethod<bool>(
      'isInstagramInstalled',
    );
    return installed ?? false;
  }

  @override
  Future<bool> shareToInstagramStory({
    required String imagePath,
    String? facebookAppId,
  }) async {
    final ok = await methodChannel.invokeMethod<bool>('shareToInstagramStory', {
      'imagePath': imagePath,
      'facebookAppId': ?facebookAppId,
    });
    return ok ?? false;
  }

  @override
  Future<bool> isFacebookInstalled() async {
    final installed = await methodChannel.invokeMethod<bool>(
      'isFacebookInstalled',
    );
    return installed ?? false;
  }

  @override
  Future<bool> shareToFacebookStory({
    required String imagePath,
    required String facebookAppId,
  }) async {
    final ok = await methodChannel.invokeMethod<bool>('shareToFacebookStory', {
      'imagePath': imagePath,
      'facebookAppId': facebookAppId,
    });
    return ok ?? false;
  }
}
