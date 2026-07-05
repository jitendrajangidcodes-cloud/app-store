package com.pnsjy.store

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// Bridges the store's Dart layer to the two Android capabilities Flutter cannot
// do directly: reading an installed app's version, and handing an APK to the
// system package installer (the one-tap install/update the OS always confirms).
class MainActivity : FlutterActivity() {
    private val channel = "com.pnsjy.store/installer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installedInfo" -> result.success(installedInfo(call.argument("packageId")))
                    "canInstall" -> result.success(canInstall())
                    "openInstallPermissionSettings" -> {
                        openInstallPermissionSettings()
                        result.success(null)
                    }
                    "openApp" -> result.success(openApp(call.argument("packageId")))
                    "uninstallApp" -> result.success(uninstallApp(call.argument("packageId")))
                    "installApk" -> result.success(installApk(call.argument("path")))
                    else -> result.notImplemented()
                }
            }
    }

    private fun installedInfo(packageId: String?): Map<String, Any?>? {
        if (packageId == null) return null
        return try {
            val info = packageManager.getPackageInfo(packageId, 0)
            val code = if (android.os.Build.VERSION.SDK_INT >= 28) info.longVersionCode
            else @Suppress("DEPRECATION") info.versionCode.toLong()
            mapOf("versionName" to info.versionName, "versionCode" to code)
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
    }

    private fun canInstall(): Boolean {
        return if (android.os.Build.VERSION.SDK_INT >= 26) packageManager.canRequestPackageInstalls()
        else true
    }

    // Lands the user on this app's own "install unknown apps" toggle (not a
    // generic settings list), matching the same pattern used by every other
    // app in this family's own update-checker (see e.g. Cards'/AI Scanner's
    // UpdateChecker.kt).
    private fun openInstallPermissionSettings() {
        val intent = Intent(android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun openApp(packageId: String?): Boolean {
        if (packageId == null) return false
        val intent = packageManager.getLaunchIntentForPackage(packageId) ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        return true
    }

    private fun uninstallApp(packageId: String?): Boolean {
        if (packageId == null) return false
        val intent = Intent(Intent.ACTION_DELETE, Uri.parse("package:$packageId"))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        return true
    }

    private fun installApk(path: String?): Boolean {
        if (path == null) return false
        val file = File(path)
        if (!file.exists()) return false
        val uri: Uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
        return true
    }
}
