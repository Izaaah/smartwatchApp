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
  final List<double> _hrBuffer = [];
  final List<double> _accMagBuffer = [];
  final int _windowSize = 60; // Sesuai WINDOW di training Python (60 detik)

  void initListener() {
    if (_subscription != null) return;

    _subscription = _watch.messageStream.listen((msg) async {
      if (msg is Map<String, dynamic>) {
        // 1. Ambil data sensor dari jam
        double hr = (msg['hr'] as num?)?.toDouble() ?? 0.0;
        double ax = (msg['ax'] as num?)?.toDouble() ?? 0.0;
        double ay = (msg['ay'] as num?)?.toDouble() ?? 0.0;
        double az = (msg['az'] as num?)?.toDouble() ?? 0.0;

        // 2. Hitung Magnitude Akselerometer (seperti di Python)
        double mag = math.sqrt(ax * ax + ay * ay + az * az);

        _hrBuffer.add(hr);
        _accMagBuffer.add(mag);

        // Jaga ukuran buffer agar tetap 60 (Sliding Window)
        if (_hrBuffer.length > _windowSize) _hrBuffer.removeAt(0);
        if (_accMagBuffer.length > _windowSize) _accMagBuffer.removeAt(0);

        // 3. Jika Buffer sudah penuh (60 data), hitung 12 fitur untuk AI
        if (_hrBuffer.length == _windowSize) {
          List<double> hrStats = _calculateStats(_hrBuffer);
          List<double> accStats = _calculateStats(_accMagBuffer);
          
          // Gabungkan: 6 fitur HR + 6 fitur ACC = 12 Fitur
          List<double> combinedFeatures = [...hrStats, ...accStats];

          // 4. SIMPAN KE SHARED PREFERENCES (Agar bisa dibaca Background Task)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('latest_features', jsonEncode(combinedFeatures));

          // 5. Kirim ke Stream (Untuk update UI di Dashboard)
          _sensorController.add({
            'hr': hr,
            'ax': ax,
            'ay': ay,
            'az': az,
            'features': combinedFeatures, // Data untuk prediksi AI
          });
        } else {
          // Jika belum 60 data, tetap kirim data mentah untuk UI saja
          _sensorController.add({
            'hr': hr,
            'ax': ax,
            'ay': ay,
            'az': az,
          });
        }
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
  }
}