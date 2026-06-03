import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WearOsService {
  static final WearOsService _instance = WearOsService._internal();
  factory WearOsService() => _instance;
  WearOsService._internal();

  final _watch = WatchConnectivity();
  final _sensorController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get sensorStream => _sensorController.stream;
  StreamSubscription? _subscription;

  final List<double> _hrBuffer    = [];
  final List<double> _axBuffer    = []; // ✅ Simpan ax, ay, az terpisah
  final List<double> _ayBuffer    = [];
  final List<double> _azBuffer    = [];
  final int _windowSize = 300;

  DateTime? _lastDataTime;

  void initListener() {
    if (_subscription != null) return;

    _subscription = _watch.messageStream.listen((msg) async {
      if (msg is Map<String, dynamic>) {
        final now = DateTime.now();

        if (_lastDataTime != null &&
            now.difference(_lastDataTime!).inMilliseconds < 200) {
          double hr = (msg['hr'] as num?)?.toDouble() ?? 0.0;
          double ax = (msg['ax'] as num?)?.toDouble() ?? 0.0;
          double ay = (msg['ay'] as num?)?.toDouble() ?? 0.0;
          double az = (msg['az'] as num?)?.toDouble() ?? 0.0;
          _sensorController.add({'hr': hr, 'ax': ax, 'ay': ay, 'az': az});
          return;
        }
        _lastDataTime = now;

        double hr = (msg['hr'] as num?)?.toDouble() ?? 0.0;
        double ax = (msg['ax'] as num?)?.toDouble() ?? 0.0;
        double ay = (msg['ay'] as num?)?.toDouble() ?? 0.0;
        double az = (msg['az'] as num?)?.toDouble() ?? 0.0;

        // Konversi ke unit WESAD
        double ax_wesad = (ax / 9.80665) * 64.0;
        double ay_wesad = (ay / 9.80665) * 64.0;
        double az_wesad = (az / 9.80665) * 64.0;

        if (hr > 0) {
          _hrBuffer.add(hr);
          _axBuffer.add(ax_wesad); // ✅ Simpan per axis
          _ayBuffer.add(ay_wesad);
          _azBuffer.add(az_wesad);
        }

        print("📊 Buffer: ${_hrBuffer.length}/$_windowSize (${(_hrBuffer.length / 5).toStringAsFixed(0)}s / 60s)");

        if (_hrBuffer.length >= _windowSize) {
          print("🎯 window penuh! HR sample: ${_hrBuffer.take(5).toList()}");

          // ✅ Hitung 13 fitur
          List<double> hrStats  = _calculateStats(_hrBuffer);         // 6 fitur
          double rmssd          = _calculateRmssd(_hrBuffer);          // 1 fitur ✅
          List<double> accMag   = _calculateAccMagnitude(_axBuffer, _ayBuffer, _azBuffer);
          List<double> accStats = _calculateStats(accMag);            // 6 fitur

          List<double> features = [
            ...hrStats,   // index 0-5
            rmssd,        // index 6  ✅
            ...accStats,  // index 7-12
          ];

          print("📦 13 fitur siap: $features");
          print("✅ Jumlah fitur: ${features.length}"); // Harus 13

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('latest_features', jsonEncode(features));
          print("✅ Features disimpan ke SharedPreferences");

          _hrBuffer.clear();
          _axBuffer.clear();
          _ayBuffer.clear();
          _azBuffer.clear();
        }

        _sensorController.add({'hr': hr, 'ax': ax, 'ay': ay, 'az': az});
      }
    });
  }

  // Statistik identik get_stats() Python
  List<double> _calculateStats(List<double> data) {
    if (data.isEmpty) return List.filled(6, 0.0);

    double mean = data.reduce((a, b) => a + b) / data.length;
    double sumSquaredDiff = data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b);
    double std    = math.sqrt(sumSquaredDiff / data.length);
    double min    = data.reduce(math.min);
    double max    = data.reduce(math.max);
    double range  = max - min;
    List<double> sorted = List.from(data)..sort();
    double median = sorted[sorted.length ~/ 2];

    return [mean, std, min, max, range, median];
  }

  // ✅ RMSSD identik calculate_rmssd_from_hr() Python
  double _calculateRmssd(List<double> hr) {
    if (hr.length < 2) return 0.0;

    // ibi = 60000 / (hr + 1e-6)
    List<double> ibi = hr.map((h) => 60000.0 / (h + 1e-6)).toList();

    List<double> diffs = [];
    for (int i = 1; i < ibi.length; i++) {
      diffs.add(ibi[i] - ibi[i - 1]);
    }

    double meanSquared = diffs.map((d) => d * d).reduce((a, b) => a + b) / diffs.length;
    return math.sqrt(meanSquared);
  }

  // ✅ Magnitude dari ax, ay, az terpisah
  List<double> _calculateAccMagnitude(
      List<double> ax, List<double> ay, List<double> az) {
    int len = [ax.length, ay.length, az.length].reduce((a, b) => a < b ? a : b);
    List<double> mag = [];
    for (int i = 0; i < len; i++) {
      mag.add(math.sqrt(ax[i] * ax[i] + ay[i] * ay[i] + az[i] * az[i]));
    }
    return mag;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _hrBuffer.clear();
    _axBuffer.clear();
    _ayBuffer.clear();
    _azBuffer.clear();
  }
}