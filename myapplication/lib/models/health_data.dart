import 'package:cloud_firestore/cloud_firestore.dart'; 

class HealthData {
  final double hr;
  final double ax;
  final double ay;
  final double az;
  final int? steps; 

  HealthData({
    required this.hr,
    required this.ax,
    required this.ay,
    required this.az,
    this.steps, 
  });

  factory HealthData.fromBle(String raw) {
    final p = raw.split('|');
    return HealthData(
      hr: double.parse(p[0]),
      ax: double.parse(p[1]),
      ay: double.parse(p[2]),
      az: double.parse(p[3]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hr': hr,
      'ax': ax,
      'ay': ay,
      'az': az,
      'steps': steps ?? 0, // Memberikan nilai default jika null
      'timestamp': FieldValue.serverTimestamp(), // Ini akan mencatat waktu di server Firebase
    };
  }
}