package com.example.myapplication.presentation

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.runtime.*
import androidx.core.content.ContextCompat
import androidx.wear.compose.material.MaterialTheme

class MainActivity : ComponentActivity() {

    private val viewModel by viewModels<SensorViewModel>()

    // Launcher Izin
    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { result ->
        if (result.all { it.value }) {
            Log.d("WATCH_APP", "Semua izin diberikan, memulai service...")
            startSensorService()
        } else {
            Log.e("WATCH_APP", "Izin ditolak oleh pengguna")
        }
    }

    // Receiver untuk menangkap data dari Service ke UI
    private val sensorReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            // Update data ke ViewModel agar UI tersinkronisasi
            val hr = intent?.getFloatExtra("HR", 0f) ?: 0f
            val ax = intent?.getFloatExtra("AX", 0f) ?: 0f
            val ay = intent?.getFloatExtra("AY", 0f) ?: 0f
            val az = intent?.getFloatExtra("AZ", 0f) ?: 0f
            val steps = intent?.getFloatExtra("STEPS", 0f) ?: 0f // Ambil data steps

            viewModel.updateSensor(hr, ax, ay, az, steps)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        SensorService.viewModel = viewModel

        setContent {
            MaterialTheme {
                // Ambil state dari ViewModel secara reaktif
                val hr by viewModel.hr
                val ax by viewModel.ax
                val ay by viewModel.ay
                val az by viewModel.az
                val steps by viewModel.steps // Pastikan ada di ViewModel
                val isSending by viewModel.isSending

                SensorScreen(
                    hr = hr,
                    ax = ax,
                    ay = ay,
                    az = az,
                    steps = steps, // Masukkan ke parameter SensorScreen
                    isSending = isSending
                )
            }
        }

        val filter = IntentFilter("SENSOR_DATA_UPDATED")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(sensorReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(sensorReceiver, filter)
        }

        checkAndRequestPermissions()
    }

    private fun checkAndRequestPermissions() {
        val permissions = mutableListOf(
            Manifest.permission.BODY_SENSORS,
            // WAJIB UNTUK STEPS:
            Manifest.permission.ACTIVITY_RECOGNITION
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        val allGranted = permissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }

        if (allGranted) {
            startSensorService()
        } else {
            permissionLauncher.launch(permissions.toTypedArray())
        }
    }

    private fun startSensorService() {
        val intent = Intent(this, SensorService::class.java)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (e: Exception) {
            Log.e("WATCH_APP", "Gagal menjalankan service: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(sensorReceiver)
        } catch (e: Exception) {}
    }
}