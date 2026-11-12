package com.lenscopy.app

import android.app.Activity
import android.app.StatusBarManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.lenscopy.app/screen_capture"
    private var pendingResult: MethodChannel.Result? = null
    private var initialScreenshotPath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val path = intent?.getStringExtra("screenshot_path")
        if (!path.isNullOrEmpty()) {
            initialScreenshotPath = path
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialScreenshot" -> {
                    val path = initialScreenshotPath
                    initialScreenshotPath = null
                    result.success(path)
                }
                "captureScreen" -> {
                    pendingResult = result
                    val intent = Intent(this, ScreenCaptureActivity::class.java)
                    startActivityForResult(intent, 1001)
                }
                "isTileAvailable" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
                }
                "requestAddTile" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val statusBarManager = getSystemService(Context.STATUS_BAR_SERVICE) as? StatusBarManager
                        statusBarManager?.requestAddTileService(
                            ComponentName(this, LensCopyTileService::class.java),
                            "LensCopy Scan",
                            Icon.createWithResource(this, R.drawable.ic_lenscopy_tile),
                            ContextCompat.getMainExecutor(this)
                        ) { resultCode ->
                            result.success(resultCode == StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ADDED)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1001) {
            val path = data?.getStringExtra("screenshot_path")
            pendingResult?.success(path)
            pendingResult = null
        }
    }
}
