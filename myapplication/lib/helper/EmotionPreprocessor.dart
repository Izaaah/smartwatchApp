import 'dart:math'; // Dibutuhkan untuk pow, sqrt, min, max

class EmotionPreprocessor {
  // 1. Fungsi Hitung Statistik (Identik dengan get_stats di Python)
  static List<double> calculateStats(List<double> data) {
    if (data.isEmpty) return List.filled(6, 0.0);

    double sum = data.reduce((a, b) => a + b);
    double mean = sum / data.length;

    double variance = data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    double std = sqrt(variance);

    double minVal = data.reduce(min);
    double maxVal = data.reduce(max);
    double range = maxVal - minVal;

    List<double> sorted = List.from(data)..sort();
    double median = sorted[sorted.length ~/ 2];

    return [mean, std, minVal, maxVal, range, median];
  }

  // 2. Fungsi Normalisasi (StandardScaler)
  static List<double> normalize(List<double> features, Map<String, dynamic> scaler) {
    List<double> means = List<double>.from(scaler['mean']);
    List<double> stds = List<double>.from(scaler['std']);
    List<double> scaled = [];

    for (int i = 0; i < features.length; i++) {
      scaled.add((features[i] - means[i]) / stds[i]);
    }
    return scaled;
  }
}