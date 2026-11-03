package id.novrira.videouniquifier

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "id.novrira.videouniquifier/media_scanner"
    private val CHANNEL_AI = "id.novrira.videouniquifier/ai_super_res"
    private val CHANNEL_DEVICE = "id.novrira.videouniquifier/device_capability"
    private val CHANNEL_WAKELOCK = "id.novrira.videouniquifier/wakelock"

    private var wakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registerNotificationChannels()
        setupAiChannel(flutterEngine)
        setupScannerChannel(flutterEngine)
        setupDeviceChannel(flutterEngine)
        setupWakeLockChannel(flutterEngine)
    }

    private fun registerNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            val processChannel = NotificationChannel(
                "nra_video_processing_channel",
                "Pemrosesan Video NRA",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Menampilkan progres rendering dan status video"
                setShowBadge(false)
            }
            val completeChannel = NotificationChannel(
                "video_complete_channel",
                "Video Processing Complete",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts when video processing finishes"
            }
            val uniquifierChannel = NotificationChannel(
                "nra_uniquifier_channel",
                "NRA Uniquifier Processing",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikasi status proses video dan ekspor aset"
                enableVibration(true)
            }
            notificationManager?.createNotificationChannel(uniquifierChannel)
            notificationManager?.createNotificationChannel(processChannel)
            notificationManager?.createNotificationChannel(completeChannel)
        }
    }

    private fun setupAiChannel(flutterEngine: FlutterEngine) {
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
                "processFrameBatch" -> result.success(true)
                else -> result.notImplemented()
            }
        }
    }

    private fun setupScannerChannel(flutterEngine: FlutterEngine) {
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
                            ) { _, _ -> }
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

    private fun setupDeviceChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_DEVICE).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceSpecs" -> {
                    try {
                        val actManager = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                        val memInfo = ActivityManager.MemoryInfo()
                        actManager?.getMemoryInfo(memInfo)
                        val totalRamBytes = memInfo.totalMem
                        val availRamBytes = memInfo.availMem
                        val cpuCores = Runtime.getRuntime().availableProcessors()
                        val abi = if (Build.SUPPORTED_ABIS.isNotEmpty()) Build.SUPPORTED_ABIS[0] else "unknown"
                        val isArm64 = abi.contains("arm64") || abi.contains("aarch64")

                        val pm = applicationContext.packageManager
                        val hasVulkan = pm.hasSystemFeature(PackageManager.FEATURE_VULKAN_HARDWARE_LEVEL)
                        val hasVulkanCompute = pm.hasSystemFeature(PackageManager.FEATURE_VULKAN_HARDWARE_VERSION)

                        result.success(
                            mapOf(
                                "totalRamBytes" to totalRamBytes,
                                "availRamBytes" to availRamBytes,
                                "cpuCores" to cpuCores,
                                "primaryAbi" to abi,
                                "isArm64" to isArm64,
                                "hasVulkan" to hasVulkan,
                                "hasVulkanCompute" to (hasVulkan || hasVulkanCompute)
                            )
                        )
                    } catch (e: Exception) {
                        result.error("SPECS_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setupWakeLockChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_WAKELOCK).setMethodCallHandler { call, result ->
            when (call.method) {
                "acquireWakeLock" -> {
                    try {
                        if (wakeLock == null) {
                            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                            wakeLock = powerManager?.newWakeLock(
                                PowerManager.PARTIAL_WAKE_LOCK,
                                "VideoUniquifier:ProcessingWakeLock"
                            )
                        }
                        if (wakeLock?.isHeld == false) {
                            wakeLock?.acquire(60 * 60 * 1000L) // Safety cap 1 hour
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WAKELOCK_ERROR", e.message, null)
                    }
                }
                "releaseWakeLock" -> {
                    try {
                        if (wakeLock?.isHeld == true) {
                            wakeLock?.release()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WAKELOCK_ERROR", e.message, null)
                    }
                }
                "isWakeLockHeld" -> {
                    result.success(wakeLock?.isHeld == true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
