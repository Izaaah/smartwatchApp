package com.example.myapplication.presentation

import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel

class SensorViewModel : ViewModel() {

    var hr = mutableStateOf(0f)
        private set

    var ax = mutableStateOf(0f)
        private set

    var ay = mutableStateOf(0f)
        private set

    var az = mutableStateOf(0f)
        private set

    val steps = mutableStateOf(0f)

    var isSending = mutableStateOf(false)
        private set

    fun updateSensor(hr: Float, ax: Float, ay: Float, az: Float, stepsVal: Float) {
        this.hr.value = hr
        this.ax.value = ax
        this.ay.value = ay
        this.az.value = az
        this.steps.value = stepsVal
        isSending.value = true
    }
}
