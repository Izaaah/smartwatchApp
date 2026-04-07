import 'dart:math'; // Dibutuhkan untuk pow, sqrt, min, max

class EmotionPreprocessor {
  // 1. Fungsi Hitung Statistik (Identik dengan get_stats di Python)
  static List<double> calculateStats(List<double> data) {
    if (data.isEmpty) return List.filled(6, 0.0);

    double sum = data.reduce((a, b) => a + b);
    double mean = sum / data.length;

    double variance = data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    double std = sqrt(variance);

    List<double> sorted = List.from(data)..sort();
    double minVal = data.reduce(min);
    double maxVal = data.reduce(max);
    double range = maxVal - minVal;
    double median = sorted[sorted.length ~/ 2];

    return [mean, std, minVal, maxVal, range, median];
  }

  static List<double> calculateAccMagnitude(
    List<double> ax, List<double> ay, List<double> az) {
      List<double> magnitude = [];
      int len = [ax.length, ay.length, az.length].reduce((a,b) => a < b ? a : b);
      for (int i = 0; i < len; i++) {
        magnitude.add(sqrt(ax[i] * ax[i] + ay[i] * ay[i] + az[i] * az[i]));
      }
      return magnitude;
    }
  // }

  static List<double> extractFeatures(
    List<double> hr, List<double> ax, List<double> ay, List<double> az) {
      List<double> accMag = calculateAccMagnitude(ax, ay, az);
      List<double> features = [];
      features.addAll(calculateStats(hr));
      features.addAll(calculateStats(accMag));
      return features;
    }
  // 2. Fungsi Normalisasi (StandardScaler)
  // static List<double> normalize(List<double> features, Map<String, dynamic> scaler) {
  //   List<double> means = List<double>.from(scaler['mean']);
  //   List<double> stds = List<double>.from(scaler['std']);
  //   List<double> scaled = [];

  //   for (int i = 0; i < features.length; i++) {
  //     scaled.add((features[i] - means[i]) / stds[i]);
  //   }
  //   return scaled;
  // }
}