package com.runterra.wear

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

/**
 * Platform plugin that reads heart rate from the Wear OS sensor and
 * emits BPM values to Flutter via an EventChannel.
 *
 * Channel name: com.runterra.wear/heart_rate
 * Emits: Int (BPM)
 */
class HeartRatePlugin : FlutterPlugin, EventChannel.StreamHandler, SensorEventListener {

    private var sensorManager: SensorManager? = null
    private var heartRateSensor: Sensor? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        sensorManager = binding.applicationContext
            .getSystemService(Context.SENSOR_SERVICE) as SensorManager
        heartRateSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_HEART_RATE)

        EventChannel(binding.binaryMessenger, "com.runterra.wear/heart_rate")
            .setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        sensorManager?.unregisterListener(this)
        eventSink = null
    }

    // EventChannel.StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        heartRateSensor?.let { sensor ->
            sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)
        } ?: events?.error("UNAVAILABLE", "Heart rate sensor not found on this device", null)
    }

    override fun onCancel(arguments: Any?) {
        sensorManager?.unregisterListener(this)
        eventSink = null
    }

    // SensorEventListener

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_HEART_RATE) {
            val bpm = event.values[0].toInt()
            if (bpm > 0) {
                eventSink?.success(bpm)
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not needed for this use case
    }
}
