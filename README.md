# social_story_share

Share an image to Instagram Stories or Facebook Stories from Flutter, without
pulling in the Facebook SDK.

## Why this exists

Most existing Flutter packages that share to Instagram or Facebook Stories 
transitively depend on the Facebook SDK. This package implements the same 
image-to-Stories deep links directly against Meta's public pasteboard 
contract, so you can ship Instagram/Facebook Stories sharing without 
adding the Facebook SDK to your app.

Meta's public Sharing-to-Stories API does not support tap-through link
stickers from third-party apps, so this package ships image-only sharing.

## Usage

```dart
import 'package:social_story_share/social_story_share.dart';

final share = SocialStoryShare();

if (await share.isInstagramInstalled()) {
  await share.shareToInstagramStory(
    imagePath: '/path/to/your/1080x1920.png',
    facebookAppId: '160023622793',
  );
}

if (await share.isFacebookInstalled()) {
  await share.shareToFacebookStory(
    imagePath: '/path/to/your/1080x1920.png',
    facebookAppId: '160023622793', // required
  );
}
```

Facebook Stories ships visual-only: see the Facebook section below for the
link-sticker limitation.

## Setup

### iOS

Add Instagram's URL schemes to your app's `Info.plist` so `canOpenURL` (used
for `isInstagramInstalled`) and the deep link can resolve:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>instagram</string>
  <string>instagram-stories</string>
</array>
```

You also need a registered Facebook App ID. Instagram requires a non-empty,
validly registered `source_application` value or it rejects the share with
"The app you shared from doesn't currently support sharing to Stories." Grab
the numeric ID from your app's Settings → Basic page at developers.facebook.com.

### Android

The plugin's `AndroidManifest.xml` already declares the `<queries>` entries for
Instagram and Facebook package visibility on Android 11+.

You must also configure a `FileProvider` in your host app so the image can be
handed to Instagram or Facebook via a content URI. Authority must be
`${applicationId}.fileprovider`:

```xml
<!-- android/app/src/main/AndroidManifest.xml, inside <application> -->
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_provider_paths" />
</provider>
```

And `android/app/src/main/res/xml/file_provider_paths.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <cache-path name="cache" path="." />
    <files-path name="files" path="." />
</paths>
```

## Facebook Stories

Facebook Stories sharing mirrors Instagram's flow but with one critical
difference: **a real, registered Facebook App ID is required.** Unlike
Instagram (where any non-empty `source_application` value satisfies the deep
link), Facebook validates the App ID against Meta's registry and rejects
unknown values with:

> The app you shared from doesn't currently support sharing to Stories.

So `facebookAppId` is a required parameter on `shareToFacebookStory(...)` and
there is no bundle-ID fallback. Grab the numeric ID from your app's
Settings → Basic page at developers.facebook.com.

### Link-sticker limitation

Facebook Stories has the same restricted Link-sticker API as Instagram: the
public Sharing-to-Stories integration does not expose a way to inject a
tappable link sticker. `shareToFacebookStory` ships the background image only.

### iOS

Add Facebook's URL schemes to your app's `Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>instagram</string>
  <string>instagram-stories</string>
  <string>facebook</string>
  <string>facebook-stories</string>
</array>
```

### Android

The plugin's `AndroidManifest.xml` already declares the `<queries>` entry for
the Facebook package and `com.facebook.stories.ADD_TO_STORY` intent. The
`FileProvider` configured for Instagram is reused for Facebook.

### Testing the example app

The example app's bundle IDs (`org.kqed.socialStoryShareExample` on iOS,
`org.kqed.social_story_share_example` on Android) are not registered against
any Facebook App ID. Testing the example specifically with a real Facebook
App ID — including KQED's production ID `160023622793` — requires registering
one of those bundles against that App ID in Meta's dashboard. Without that
registration, Facebook will return the "doesn't currently support sharing"
error from the Facebook side, even though the deep link itself dispatches.

## Status

- **Supported:** iOS, Android — image sharing to Instagram Stories and
  Facebook Stories.
- **Not supported:** web, macOS, Windows, Linux. Stories is a mobile-only
  concept on both platforms.

## License

See `LICENSE`.
