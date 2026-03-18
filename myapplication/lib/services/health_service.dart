import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

class HealthService {
  final Health health = Health();

  final types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_SESSION,
  ];

  Future<bool> requestPermissions() async {
    try {
      await health.installHealthConnect();
      return await health.requestAuthorization(types);
    } catch (e) {
      debugPrint("Izin Gagal: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchTodayData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final yesterday = now.subtract(const Duration(hours: 48));

    try {
      List<HealthDataPoint> dataPoints = await health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: types,
      );

      int stepsToday = 0;
      double caloriesToday = 0;
      double lastOxygen = 0;
      double sleepMinutes = 0; // Pastikan variabel ini ada di sini
      double lastHr = 0;

      for (var point in dataPoints) { // Kita beri nama 'point'
        bool isToday = point.dateFrom.isAfter(midnight);

        switch (point.type) {
          case HealthDataType.STEPS:
            if (isToday) stepsToday += int.parse(point.value.toString());
            break;
            
          case HealthDataType.ACTIVE_ENERGY_BURNED:
          case HealthDataType.BASAL_ENERGY_BURNED:
            if (isToday) caloriesToday += double.parse(point.value.toString());
            break;

          case HealthDataType.BLOOD_OXYGEN:
            double oxValue = double.parse(point.value.toString());
            lastOxygen = oxValue < 1.0 ? oxValue * 100 : oxValue;
            break;

          case HealthDataType.SLEEP_SESSION:
            // Perbaikan error 'p': gunakan 'point' sesuai nama variabel di atas
            final duration = point.dateTo.difference(point.dateFrom).inMinutes;
            sleepMinutes += duration.toDouble();
            break;

          case HealthDataType.HEART_RATE:
            if (isToday) lastHr = double.parse(point.value.toString());
            break;
            
          default: break;
        }
      }

      return {
        'steps': stepsToday,
        'calories': caloriesToday,
        'heartRate': lastHr,
        'oxygen': lastOxygen,
        'sleep': sleepMinutes / 60, // Menghasilkan jam
      };
    } catch (e) {
      debugPrint("Error Fetch: $e");
      return {'steps': 0, 'calories': 0, 'heartRate': 0, 'oxygen': 0, 'sleep': 0};
    }
  }
}