import 'package:health/health.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthConnectService {
  final Health health = Health();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.DISTANCE_DELTA,
  ];

  final List<HealthDataAccess> permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<bool> requestPermissions() async {
    health.configure();
    try {
      // bool requested = await health.requestAuthorization(types, permissions: permissions);
      await health.requestAuthorization(types, permissions: permissions);
      // print("🏥 requestAuthorization result: $requested");
      return true;
    } catch (e) {
      print("🏥 ERROR requestAuthorization: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchTodayData() async {
    health.configure();

    try {
    await health.requestAuthorization(types, permissions: permissions);
  } catch (e) {
    print("⚠️ requestAuthorization error (ignored): $e");
  }

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final sleepStart = midnight.subtract(const Duration(hours: 6));

      // Ambil steps aggregate
      int totalSteps = 0;
      try {
        int? steps = await health.getTotalStepsInInterval(midnight, now);
        totalSteps = steps ?? 0;
      } catch (e) {
        print("⚠️ Gagal ambil aggregate steps: $e");
      }

      // Ambil raw data
      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        types: [
          HealthDataType.STEPS,
          HealthDataType.BLOOD_OXYGEN,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.BASAL_ENERGY_BURNED,
          HealthDataType.DISTANCE_DELTA,
        ],
        startTime: midnight,
        endTime: now,
      );

      List<HealthDataPoint> sleepData = await health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_SESSION],
        startTime: sleepStart,  // kemarin jam 18:00
        endTime: now,
      );

      double sleepHours = 0;
      for (var p in sleepData) {
        print("😴 SLEEP: ${p.dateFrom} → ${p.dateTo}");
        sleepHours += p.dateTo.difference(p.dateFrom).inMinutes / 60;
      }

      double bloodOxygen = 0;
      double activeCalories = 0;
      double basalCalories = 0;

      // Fallback steps kalau aggregate gagal
      if (totalSteps == 0) {
        for (var p in healthData) {
          if (p.type == HealthDataType.STEPS) {
            totalSteps += (p.value as num).toInt();
          }
        }
      }

      for (var p in healthData) {
        print("📊 Total healthData points: ${healthData.length}");
        print("📊 TYPE: ${p.type} | VALUE: ${p.value} | FROM: ${p.dateFrom} | TO: ${p.dateTo}");
      switch (p.type) {
        case HealthDataType.SLEEP_SESSION:
          sleepHours += p.dateTo.difference(p.dateFrom).inMinutes / 60;
          break;
        case HealthDataType.BLOOD_OXYGEN:
          bloodOxygen = double.tryParse(p.value.toString()) ?? 0;
          break;
        case HealthDataType.ACTIVE_ENERGY_BURNED:       // ✅ tambah
          activeCalories += double.tryParse(p.value.toString()) ?? 0;
          break;
        case HealthDataType.BASAL_ENERGY_BURNED:        // ✅ tambah
          basalCalories += double.tryParse(p.value.toString()) ?? 0;
          break;
        default:
          break;
      }
      }

      print("🔥 Steps: $totalSteps | Sleep: $sleepHours | Oxygen: $bloodOxygen");

      return {
        'steps': totalSteps,
        'sleep': double.parse(sleepHours.toStringAsFixed(1)),
        'oxygen': bloodOxygen,
      };
    } catch (e) {
      print("❌ Error fetchTodayData: $e");
      return {'steps': 0, 'sleep': 0.0, 'oxygen': 0.0};
    }
  }

  Future<void> syncHealthData() async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    health.configure();

    // ✅ Pakai permissions list yang konsisten
    bool requested = await health.requestAuthorization(types, permissions: permissions);
    if (!requested) {
      print("⚠️ syncHealthData: permission tidak granted");
      return;
    }

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final sleepStart = midnight.subtract(const Duration(hours: 6));

      int? steps = await health.getTotalStepsInInterval(midnight, now);

      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        types: types,
        startTime: midnight.subtract(const Duration(days: 1)),
        endTime: now,
      );

      double activeCalories = 0;
      double basalCalories = 0;
      double distance = 0;
      double bloodOxygen = 0;
      double sleepHours = 0;

      for (var p in healthData) {
        switch (p.type) {
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            activeCalories += double.parse(p.value.toString());
            break;
          case HealthDataType.BASAL_ENERGY_BURNED:
            basalCalories += double.parse(p.value.toString());
            break;
          case HealthDataType.DISTANCE_DELTA:
            distance += double.parse(p.value.toString());
            break;
          case HealthDataType.BLOOD_OXYGEN:
            bloodOxygen = double.parse(p.value.toString());
            break;
          case HealthDataType.SLEEP_SESSION:
            sleepHours += p.dateTo.difference(p.dateFrom).inMinutes / 60;
            break;
          default:
            break;
        }
      }

      await _firestore.collection('users').doc(uid).set({
        'steps': steps ?? 0,
        'distance': distance / 1000,
        'calories': activeCalories,
        'total_calories': activeCalories,
        'blood_oxygen': bloodOxygen,
        'sleep_hours': sleepHours,
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ Synced: Steps=$steps | Sleep=${sleepHours.toStringAsFixed(1)}h");
    } catch (e) {
      print("❌ Error syncHealthData: $e");
    }
  }
}