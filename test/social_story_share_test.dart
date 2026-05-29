import 'package:flutter_test/flutter_test.dart';
import 'package:social_story_share/social_story_share.dart';
import 'package:social_story_share/social_story_share_platform_interface.dart';
import 'package:social_story_share/social_story_share_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSocialStorySharePlatform
    with MockPlatformInterfaceMixin
    implements SocialStorySharePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> isInstagramInstalled() => Future.value(true);

  @override
  Future<bool> shareToInstagramStory({
    required String imagePath,
    String? facebookAppId,
  }) => Future.value(true);

  @override
  Future<bool> isFacebookInstalled() => Future.value(true);

  @override
  Future<bool> shareToFacebookStory({
    required String imagePath,
    required String facebookAppId,
  }) => Future.value(true);
}

void main() {
  final SocialStorySharePlatform initialPlatform = SocialStorySharePlatform.instance;

  test('$MethodChannelSocialStoryShare is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSocialStoryShare>());
  });

  test('getPlatformVersion', () async {
    SocialStoryShare socialStorySharePlugin = SocialStoryShare();
    MockSocialStorySharePlatform fakePlatform = MockSocialStorySharePlatform();
    SocialStorySharePlatform.instance = fakePlatform;

    expect(await socialStorySharePlugin.getPlatformVersion(), '42');
  });

  test('shareToFacebookStory delegates to platform interface', () async {
    final plugin = SocialStoryShare();
    SocialStorySharePlatform.instance = MockSocialStorySharePlatform();

    expect(await plugin.isFacebookInstalled(), isTrue);
    expect(
      await plugin.shareToFacebookStory(
        imagePath: '/tmp/demo.png',
        facebookAppId: '160023622793',
      ),
      isTrue,
    );
  });
}
