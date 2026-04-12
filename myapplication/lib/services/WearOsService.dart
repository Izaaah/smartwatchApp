import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:frontend/helper/EmotionPreprocessor.dart';

class WearOsService {
  static final WearOsService _instance = WearOsService._internal();
  factory WearOsService() => _instance;
  WearOsService._internal();

  final _watch = WatchConnectivity();
  final _sensorController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get sensorStream => _sensorController.stream;
  StreamSubscription? _subscription;

  // kumpulkan 6
  final List<double> _hrBuffer = [];
  final List<double> _accMagBuffer = [];
  final int _windowSize = 300; // Sesuai WINDOW di training Python (60 detik)
  
  DateTime? _lastDataTime;
  void initListener() {
    if (_subscription != null) return;

    _subscription = _watch.messageStream.listen((msg) async {
      if (msg is Map<String, dynamic>) {
        final now = DateTime.now();

        // Throttle
        if (_lastDataTime != null &&
            now.difference(_lastDataTime!).inMilliseconds < 200) {
              double hr = (msg['hr'] as num?)?.toDouble() ?? 0.0;
              double ax = (msg['ax'] as num?)?.toDouble() ?? 0.0;
              double ay = (msg['ay'] as num?)?.toDouble() ?? 0.0;
              double az = (msg['az'] as num?)?.toDouble() ?? 0.0;
              _sensorController.add({'hr' : hr, 'ax' : ax, 'ay' : ay, 'az' : az});
              return;
            }
            _lastDataTime = now;
        // 1. Ambil data sensor dari jam
        double hr = (msg['hr'] as num?)?.toDouble() ?? 0.0;
        double ax = (msg['ax'] as num?)?.toDouble() ?? 0.0;
        double ay = (msg['ay'] as num?)?.toDouble() ?? 0.0;
        double az = (msg['az'] as num?)?.toDouble() ?? 0.0;

        // 2. Hitung Magnitude Akselerometer (seperti di Python)
        double mag = math.sqrt(ax * ax + ay * ay + az * az);

        if (hr > 0) {
          _hrBuffer.add(hr);
          _accMagBuffer.add(mag);
        }

        print("📊 Buffer: ${_hrBuffer.length}/$_windowSize (${(_hrBuffer.length/5).toStringAsFixed(0)}s / 60s)");

        if (_hrBuffer.length >= _windowSize) {
          print("🎯 window penuh! HR sample: ${_hrBuffer.take(5).toList()}");
          print("🎯 ACC Mag sample: ${_accMagBuffer.take(5).toList()}");
          
          List<double> hrStats = _calculateStats(_hrBuffer);
          List<double> accStats = _calculateStats(_accMagBuffer);

          List<double> features = [...hrStats, ...accStats];
          print("📦 12 fitur siap: $features");

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('latest_features', jsonEncode(features));
          print("✅ Features disimpan ke SharedPreferences");

          _hrBuffer.clear();
          _accMagBuffer.clear();
        }

        _sensorController.add({
          'hr' : hr,
          'ax' : ax,
          'ay' : ay,
          'az' : az,
        });
      }
    });
  }

  // Fungsi Statistik: Hasil harus identik dengan get_stats() di Python
  List<double> _calculateStats(List<double> data) {
  if (data.isEmpty) return List.filled(6, 0.0);

  // 1. Mean
  double mean = data.reduce((a, b) => a + b) / data.length;

  // 2. Standard Deviation (Perbaikan di sini)
  double sumSquaredDiff = data
      .map((x) => (x - mean) * (x - mean))
      .reduce((a, b) => a + b);
  double std = math.sqrt(sumSquaredDiff / data.length);

  // 3. Min & 4. Max
  double min = data.reduce(math.min);
  double max = data.reduce(math.max);

  // 5. Range
  double range = max - min;

  // 6. Median
  List<double> sorted = List.from(data)..sort();
  double median = sorted[sorted.length ~/ 2];

  return [mean, std, min, max, range, median];
}
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _hrBuffer.clear();
    _accMagBuffer.clear();
  }
}