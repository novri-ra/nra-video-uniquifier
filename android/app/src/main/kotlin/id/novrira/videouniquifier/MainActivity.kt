package id.novrira.videouniquifier

import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "id.novrira.videouniquifier/media_scanner"
    private val CHANNEL_AI = "id.novrira.videouniquifier/ai_super_res"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_AI).setMethodCallHandler { call, result ->
            when (call.method) {
                "isVulkanSupported" -> {
                    try {
                        val pm = applicationContext.packageManager
                        val hasVulkan = pm.hasSystemFeature(PackageManager.FEATURE_VULKAN_HARDWARE_LEVEL)
                        result.success(hasVulkan)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                "getModelInfo" -> {
                    result.success(
                        mapOf(
                            "model" to "Real-ESRGAN AnimeVideo-v3 Compact (x2/x4 NCNN Vulkan)",
                            "tilingSupport" to true,
                            "fallbackEngine" to "Hardware-accelerated Lanczos3"
                        )
                    )
                }
                "processFrameBatch" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val filePath = call.argument<String>("path")
                    if (filePath != null) {
                        try {
                            MediaScannerConnection.scanFile(
                                applicationContext,
                                arrayOf(filePath),
                                arrayOf("video/mp4")
                            ) { path, uri ->
                                // Scanned successfully
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SCAN_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PATH", "Path is null", null)
                    }
                }
                "openGallery" -> {
                    val filePath = call.argument<String>("path")
                    try {
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            if (filePath != null && File(filePath).exists()) {
                                val file = File(filePath)
                                val uri: Uri = try {
                                    FileProvider.getUriForFile(
                                        applicationContext,
                                        "${applicationContext.packageName}.fileprovider",
                                        file
                                    )
                                } catch (_: Exception) {
                                    Uri.fromFile(file)
                                }
                                setDataAndType(uri, "video/*")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            } else {
                                type = "video/*"
                            }
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(Intent.createChooser(intent, "Open Video Gallery"))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
