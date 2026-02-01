package com.runterra.runterra

import android.content.pm.PackageManager
import android.os.Bundle
import com.yandex.mapkit.MapKitFactory
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // Set Yandex MapKit API key before Flutter engine initializes plugins.
        // Plugin reads manifest too late on some devices; MapKitFactory requires key before initialize().
        try {
            val ai = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
            val key = ai.metaData?.getString("com.yandex.android.mapkit.ApiKey")
            if (!key.isNullOrBlank()) {
                MapKitFactory.setApiKey(key)
            }
        } catch (_: Exception) { }
        super.onCreate(savedInstanceState)
    }
}
