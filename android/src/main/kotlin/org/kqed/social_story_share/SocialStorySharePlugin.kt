package org.kqed.social_story_share

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

/**
 * SocialStorySharePlugin — Android side.
 *
 * Shares an image to Instagram Stories via the `com.instagram.share.ADD_TO_STORY`
 * intent, or to Facebook Stories via the `com.facebook.stories.ADD_TO_STORY`
 * intent.
 */
class SocialStorySharePlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context
    private var activity: Activity? = null

    companion object {
        private const val INSTAGRAM_PACKAGE = "com.instagram.android"
        private const val ADD_TO_STORY = "com.instagram.share.ADD_TO_STORY"
        private const val FACEBOOK_PACKAGE = "com.facebook.katana"
        private const val FACEBOOK_ADD_TO_STORY = "com.facebook.stories.ADD_TO_STORY"
        // Instagram reads source_application; Facebook requires the platform extra.
        private const val EXTRA_SOURCE_APPLICATION = "source_application"
        private const val EXTRA_FACEBOOK_APPLICATION_ID =
            "com.facebook.platform.extra.APPLICATION_ID"
        // Used when packaging the image file via FileProvider.
        private const val MIME_PNG = "image/png"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "social_story_share")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        when (call.method) {
            "getPlatformVersion" ->
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "isInstagramInstalled" -> result.success(isInstagramInstalled())
            "shareToInstagramStory" -> shareToInstagramStory(call, result)
            "isFacebookInstalled" -> result.success(isFacebookInstalled())
            "shareToFacebookStory" -> shareToFacebookStory(call, result)
            else -> result.notImplemented()
        }
    }

    private fun isInstagramInstalled(): Boolean {
        return try {
            applicationContext.packageManager.getPackageInfo(INSTAGRAM_PACKAGE, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun shareToInstagramStory(
        call: MethodCall,
        result: Result,
    ) {
        val imagePath = call.argument<String>("imagePath")
        val facebookAppId = call.argument<String>("facebookAppId")

        if (imagePath.isNullOrEmpty() || facebookAppId.isNullOrEmpty()) {
            result.error(
                "INVALID_ARGS",
                "imagePath and a non-empty facebookAppId are required.",
                null,
            )
            return
        }

        val currentActivity = activity
        if (currentActivity == null) {
            result.error(
                "NO_ACTIVITY",
                "Plugin was not attached to an Activity.",
                null,
            )
            return
        }

        if (!isInstagramInstalled()) {
            result.error(
                "INSTAGRAM_UNAVAILABLE",
                "Instagram is not installed.",
                null,
            )
            return
        }

        val imageFile = File(imagePath)
        if (!imageFile.exists()) {
            result.error(
                "IMAGE_READ_FAILED",
                "Image not found at $imagePath.",
                null,
            )
            return
        }

        val imageUri: Uri =
            try {
                FileProvider.getUriForFile(
                    applicationContext,
                    "${applicationContext.packageName}.fileprovider",
                    imageFile,
                )
            } catch (e: IllegalArgumentException) {
                result.error(
                    "FILEPROVIDER_MISCONFIGURED",
                    "Could not expose the image via FileProvider. Make sure the " +
                        "host app declares a FileProvider authority of " +
                        "\"${applicationContext.packageName}.fileprovider\" and " +
                        "a paths file that includes the temp directory used " +
                        "for the rendered image. ${e.message}",
                    null,
                )
                return
            }

        val intent =
            Intent(ADD_TO_STORY).apply {
                setDataAndType(imageUri, MIME_PNG)
                putExtra(EXTRA_SOURCE_APPLICATION, facebookAppId)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                setPackage(INSTAGRAM_PACKAGE)
            }

        try {
            currentActivity.startActivityForResult(intent, 0)
            result.success(true)
        } catch (_: ActivityNotFoundException) {
            result.error(
                "INSTAGRAM_UNAVAILABLE",
                "Instagram could not handle the ADD_TO_STORY intent.",
                null,
            )
        }
    }

    private fun isFacebookInstalled(): Boolean {
        return try {
            applicationContext.packageManager.getPackageInfo(FACEBOOK_PACKAGE, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun shareToFacebookStory(
        call: MethodCall,
        result: Result,
    ) {
        val imagePath = call.argument<String>("imagePath")
        val facebookAppId = call.argument<String>("facebookAppId")

        // Facebook validates source_application against Meta's registry —
        // unknown values get rejected, so unlike Instagram there is no
        // bundle-ID fallback. A real registered Facebook App ID is required.
        if (imagePath.isNullOrEmpty() || facebookAppId.isNullOrEmpty()) {
            result.error(
                "INVALID_ARGS",
                "imagePath and a non-empty facebookAppId are required.",
                null,
            )
            return
        }

        val currentActivity = activity
        if (currentActivity == null) {
            result.error(
                "NO_ACTIVITY",
                "Plugin was not attached to an Activity.",
                null,
            )
            return
        }

        if (!isFacebookInstalled()) {
            result.error(
                "FACEBOOK_UNAVAILABLE",
                "Facebook is not installed.",
                null,
            )
            return
        }

        val imageFile = File(imagePath)
        if (!imageFile.exists()) {
            result.error(
                "IMAGE_READ_FAILED",
                "Image not found at $imagePath.",
                null,
            )
            return
        }

        val imageUri: Uri =
            try {
                FileProvider.getUriForFile(
                    applicationContext,
                    "${applicationContext.packageName}.fileprovider",
                    imageFile,
                )
            } catch (e: IllegalArgumentException) {
                result.error(
                    "FILEPROVIDER_MISCONFIGURED",
                    "Could not expose the image via FileProvider. Make sure the " +
                        "host app declares a FileProvider authority of " +
                        "\"${applicationContext.packageName}.fileprovider\" and " +
                        "a paths file that includes the temp directory used " +
                        "for the rendered image. ${e.message}",
                    null,
                )
                return
            }

        currentActivity.grantUriPermission(
            FACEBOOK_PACKAGE,
            imageUri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION,
        )

        val intent =
            Intent(FACEBOOK_ADD_TO_STORY).apply {
                setDataAndType(imageUri, MIME_PNG)
                putExtra(EXTRA_FACEBOOK_APPLICATION_ID, facebookAppId)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                setPackage(FACEBOOK_PACKAGE)
            }

        try {
            currentActivity.startActivityForResult(intent, 0)
            result.success(true)
        } catch (_: ActivityNotFoundException) {
            result.error(
                "FACEBOOK_UNAVAILABLE",
                "Facebook could not handle the ADD_TO_STORY intent.",
                null,
            )
        }
    }
}
