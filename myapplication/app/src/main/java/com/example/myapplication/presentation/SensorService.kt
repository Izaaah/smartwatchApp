package com.example.myapplication.presentation

import android.app.*
import android.hardware.*
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.wearable.Wearable
import java.io.ByteArrayOutputStream
import java.io.ObjectOutputStream
import java.util.HashMap
import android.content.Intent
import android.os.IBinder

class SensorService : Service(), SensorEventListener {

    private lateinit var sensorManager: SensorManager

    // ===============================
    // SENSOR DATA
    // ===============================
    private var currentHeartRate = 0f
    private var ax = 0f
    private var ay = 0f
    private var az = 0f
    private var currentSteps = 0f

    // ===============================
    // TIME THROTTLE CONFIG
    // ===============================
    private var lastSentTime = 0L
    private val SEND_INTERVAL_MS = 200L // 3x per detik (hemat baterai)

    override fun onCreate() {
        super.onCreate()

        sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager

        createNotificationChannel()
        startForeground(1, createNotification())

        registerSensors()
    }

    private fun registerSensors() {

        // Heart Rate
        sensorManager.getDefaultSensor(Sensor.TYPE_HEART_RATE)?.let {
            sensorManager.registerListener(
                this,
                it,
                SensorManager.SENSOR_DELAY_NORMAL
            )
        }

        // Accelerometer (turun rate = hemat baterai)
        sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)?.let {
            sensorManager.registerListener(
                this,
                it,
                SensorManager.SENSOR_DELAY_NORMAL
            )
        }

        sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
        }

        val stepCounter = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        val stepDetector = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)

        stepCounter?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
        stepDetector?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        // 1. Selalu perbarui nilai variabel global setiap ada perubahan sensor
        when (event.sensor.type) {
            Sensor.TYPE_HEART_RATE -> currentHeartRate = event.values[0]
            Sensor.TYPE_STEP_COUNTER -> currentSteps = event.values[0]
            Sensor.TYPE_ACCELEROMETER -> {
                ax = event.values[0]
                ay = event.values[1]
                az = event.values[2]

                // 2. KUNCI: Hanya lakukan pengiriman data di dalam event Akselerometer
                // Ini menjamin interval pengiriman yang lebih konsisten (Master Clock)
                val now = System.currentTimeMillis()
                if (now - lastSentTime >= SEND_INTERVAL_MS) {
                    lastSentTime = now

                    // Update UI Jam
                    SensorService.viewModel?.updateSensor(currentHeartRate, ax, ay, az, currentSteps)

                    // Kirim ke HP (Hapus syarat currentHeartRate > 0f agar data tetap mengalir 5Hz)
                    sendMessageToPhone(currentHeartRate, ax, ay, az, currentSteps)
                }
            }
        }
    }

//    override fun onSensorChanged(event: SensorEvent) {
//
//        when (event.sensor.type) {
//            Sensor.TYPE_STEP_COUNTER -> {
//                // Nilai ini adalah total langkah sejak boot
//                currentSteps = event.values[0]
//            }
//            Sensor.TYPE_STEP_DETECTOR -> {
//                // Setiap ada getaran langkah, detector mengirim nilai 1.0
//                if (event.values[0] == 1.0f) {
//                    Log.i("WATCH", "Langkah Terdeteksi!")
//                }
//            }
//
//            Sensor.TYPE_HEART_RATE -> {
//                currentHeartRate = event.values[0]
//            }
//
//            Sensor.TYPE_ACCELEROMETER -> {
//                ax = event.values[0]
//                ay = event.values[1]
//                az = event.values[2]
//            }
//
//            Sensor.TYPE_STEP_COUNTER -> {
//                currentSteps = event.values[0]
//            }
//        }
//
//        // ===============================
//        // TIME THROTTLE
//        // ===============================
//        val now = System.currentTimeMillis()
//        if (now - lastSentTime < SEND_INTERVAL_MS) return
//        lastSentTime = now
//
//        // ===============================
//        // UPDATE UI WATCH (COMPOSE)
//        // ===============================
//        SensorService.viewModel?.updateSensor(
//            currentHeartRate,
//            ax,
//            ay,
//            az,
//            currentSteps
//        )
//
//        // ===============================
//        // KIRIM KE HP (FLUTTER)
//        // ===============================
//        if (currentHeartRate > 0f) {
//            sendMessageToPhone(
//                currentHeartRate,
//                ax,
//                ay,
//                az,
//                currentSteps
//            )
//        }
//    }

    // ===============================
    // SEND MESSAGE TO PHONE
    // ===============================
    private fun sendMessageToPhone(
        hr: Float,
        ax: Float,
        ay: Float,
        az: Float,
        steps: Float
    ) {
        val nodeClient = Wearable.getNodeClient(this)

        nodeClient.connectedNodes.addOnSuccessListener { nodes ->
            val now = System.currentTimeMillis() // Timestamp sekarang

            for (node in nodes) {
                val data = HashMap<String, Double>().apply {
                    put("hr", hr.toDouble())
                    put("ax", ax.toDouble())
                    put("ay", ay.toDouble())
                    put("az", az.toDouble())
                    put("steps", steps.toDouble())
                    put("timestamp", now.toDouble()) // Tambahkan timestamp
                }

                Wearable.getMessageClient(this)
                    .sendMessage(
                        node.id,
                        "/sensor",
                        serializeMap(data)
                    )

                Log.i("WATCH", "SEND → $data")
            }
        }
    }

    // ===============================
    // SERIALIZER (WAJIB)
    // ===============================
    private fun serializeMap(map: HashMap<String, Double>): ByteArray {
        val baos = ByteArrayOutputStream()
        val oos = ObjectOutputStream(baos)
        oos.writeObject(map)
        oos.close()
        return baos.toByteArray()
    }

    // ===============================
    // FOREGROUND NOTIFICATION
    // ===============================
    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, "sensor_channel")
            .setContentTitle("Smartwatch Sync Active")
            .setContentText("Mengirim data sensor ke HP...")
            .setSmallIcon(android.R.drawable.stat_notify_sync)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "sensor_channel",
                "Sensor Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onDestroy() {
        super.onDestroy()
        sensorManager.unregisterListener(this)
    }

    companion object {
        var viewModel: SensorViewModel? = null
    }
}
