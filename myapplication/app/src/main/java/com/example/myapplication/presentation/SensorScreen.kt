package com.example.myapplication.presentation

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color // IMPORT INI WAJIB ADA
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.*

@Composable
fun SensorScreen(
    hr: Float,
    ax: Float,
    ay: Float,
    az: Float,
    steps: Float, // Tambahkan parameter steps di sini
    isSending: Boolean = true
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(8.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(bottom = 20.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("RELY WATCH", style = MaterialTheme.typography.caption1)

            // Tampilan Heart Rate
            Text(
                "HR: ${hr.toInt()} BPM",
                style = MaterialTheme.typography.title3,
                color = MaterialTheme.colors.primary
            )

            Spacer(modifier = Modifier.height(4.dp))

            // ===============================
            // TAMPILAN STEPS (Baru)
            // ===============================
            Text(
                "STEPS: ${steps.toInt()}",
                style = MaterialTheme.typography.title3,
                color = Color(0xFF4ECDC4) // Gunakan warna Cyan agar estetik
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text("ACCELEROMETER", style = MaterialTheme.typography.caption2)
            Text("X: ${"%.2f".format(ax)}", style = MaterialTheme.typography.caption2)
            Text("Y: ${"%.2f".format(ay)}", style = MaterialTheme.typography.caption2)
            Text("Z: ${"%.2f".format(az)}", style = MaterialTheme.typography.caption2)
        }

        Text(
            text = if (isSending) "● Sending to Phone" else "○ Disconnected",
            style = MaterialTheme.typography.caption3,
            color = if (isSending) Color.Green else Color.Red,
            modifier = Modifier.align(Alignment.BottomCenter).padding(bottom = 4.dp)
        )
    }
}