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
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.DISTANCE_DELTA,
  ];

  Future<bool> requestPermissions() async {
    health.configure();

    bool? hasPermission = await health.hasPermissions(types);

    if (hasPermission == null || !hasPermission) {
      try {
        bool requested = await health.requestAuthorization(types);
        return requested;
      } catch (e) {
        print("error requesting health permission: $e");
        return false;
      }
    }
    return true;
  }

  Future<Map<String, dynamic>> fetchTodayData() async {
    // final String? uid = _auth.currentUser?.uid;

    bool authorized = await requestPermissions();
    if (!authorized) return {'steps': 0, 'sleep': 0.0, 'oxygen': 0.0};

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      int totalSteps = 0;
      try {
        int? aggregateSteps = await health.getTotalStepsInInterval(midnight, now);
        totalSteps = aggregateSteps ?? 0;
      } catch (e) {
        print("gagal ambil agregat steps");
      }

      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        types: types, 
        startTime: midnight, 
        endTime: now,);
      
      double sleepHours = 0;
      double bloodOxygen = 0;

      for (var p in healthData) {
        if (p.type == HealthDataType.SLEEP_SESSION) {
          sleepHours += p.dateTo.difference(p.dateFrom).inMinutes/60;
        } else if (p.type == HealthDataType.BLOOD_OXYGEN){
          bloodOxygen = double.tryParse(p.value.toString()) ?? 0;
        } else if (p.type == HealthDataType.STEPS && totalSteps == 0) {
          totalSteps += (double.tryParse(p.value.toString()) ?? 0).toInt();
        }
      }

      print("Debug Fetch: Steps: $totalSteps, sleep: $sleepHours, Oxygen: $bloodOxygen");

      print("RAW STEPS DATA: $totalSteps");
print("RAW SLEEP DATA: $sleepHours");
print("RAW OXYGEN DATA: $bloodOxygen");

      return {
        'steps': totalSteps,
        'sleep': sleepHours,
        'oxygen': bloodOxygen,
      };
    } catch (e) {
      print("❌ Error Fetching Data: $e");
      return {'steps': 0, 'sleep': 0.0, 'oxygen': 0.0};
    }
  }
  
  Future<void> syncHealthData() async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    health.configure();

    bool requested = await health.requestAuthorization(types);
    if (!requested) return;

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

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

      for (var p in healthData){
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
            distance = double.parse(p.value.toString());
            break;
          case HealthDataType.SLEEP_SESSION:
            if (p.dateFrom != null && p.dateTo != null) {
              sleepHours += p.dateTo.difference(p.dateFrom).inMinutes / 60;
            }
            break;
          default:
            break;
        }
      }

      await _firestore.collection('users').doc(uid).set({
        'steps': steps ?? 0,
        'distance': distance / 1000,
        'calories': activeCalories,
        'basal_calories': basalCalories,
        'total_calories': activeCalories + basalCalories,
        'blood_oxygen': bloodOxygen,
        'sleep_hours': sleepHours,
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ Health Connect Synced: Steps: $steps, Sleep: ${sleepHours.toStringAsFixed(1)}h");
    } catch (e) {
      print("❌ Error Sync Health Data: $e");
    }
  }
}