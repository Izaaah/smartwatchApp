import 'dart:math';

class EmotionPreprocessor {
  
  // 1. Statistik dasar (identik get_stats Python)
  static List<double> calculateStats(List<double> data) {
    if (data.isEmpty) return List.filled(6, 0.0);

    double sum = data.reduce((a, b) => a + b);
    double mean = sum / data.length;

    double variance = data.map((x) => pow(x - mean, 2).toDouble())
        .reduce((a, b) => a + b) / data.length;
    double std = sqrt(variance);

    List<double> sorted = List.from(data)..sort();
    double minVal = sorted.first;
    double maxVal = sorted.last;
    double range = maxVal - minVal;
    double median = sorted[sorted.length ~/ 2];

    return [mean, std, minVal, maxVal, range, median];
  }

  // 2. RMSSD dari HR (identik calculate_rmssd_from_hr Python)
  static double calculateRmssd(List<double> hr) {
    if (hr.length < 2) return 0.0;

    // Konversi HR ke IBI (Inter-Beat Interval) dalam ms
    // ibi = 60000 / (hr + 1e-6)  ← identik dengan Python
    List<double> ibi = hr.map((h) => 60000.0 / (h + 1e-6)).toList();

    // Hitung selisih antar IBI berurutan
    List<double> diffs = [];
    for (int i = 1; i < ibi.length; i++) {
      diffs.add(ibi[i] - ibi[i - 1]);
    }

    // RMSSD = sqrt(mean(diff^2))
    double meanSquared = diffs.map((d) => d * d).reduce((a, b) => a + b) / diffs.length;
    return sqrt(meanSquared);
  }

  // 3. Magnitude ACC
  static List<double> calculateAccMagnitude(
      List<double> ax, List<double> ay, List<double> az) {
    List<double> magnitude = [];
    int len = [ax.length, ay.length, az.length].reduce((a, b) => a < b ? a : b);
    for (int i = 0; i < len; i++) {
      magnitude.add(sqrt(ax[i] * ax[i] + ay[i] * ay[i] + az[i] * az[i]));
    }
    return magnitude;
  }

  // 4. Ekstraksi 13 Fitur (urutan HARUS sama dengan Python)
  static List<double> extractFeatures(
      List<double> hr, List<double> ax, List<double> ay, List<double> az) {
    
    List<double> hrStats  = calculateStats(hr);       // index 0-5  → 6 fitur HR
    double rmssd          = calculateRmssd(hr);        // index 6    → 1 fitur RMSSD
    List<double> accMag   = calculateAccMagnitude(ax, ay, az);
    List<double> accStats = calculateStats(accMag);   // index 7-12 → 6 fitur ACC

    List<double> features = [];
    features.addAll(hrStats);   // 6
    features.add(rmssd);        // 1
    features.addAll(accStats);  // 6
    // Total = 13 ✅

    print("🔍 Jumlah fitur: ${features.length}"); // Harus 13
    print("🔍 HR stats  : $hrStats");
    print("🔍 RMSSD     : $rmssd");
    print("🔍 ACC stats : $accStats");

    return features;
  }

  // 5. Normalisasi StandardScaler
  static List<double> normalize(List<double> features, Map<String, dynamic> scaler) {
    List<double> means = List<double>.from(scaler['mean']);
    List<double> stds  = List<double>.from(scaler['std']);

    // Validasi panjang
    if (features.length != means.length) {
      print("❌ Mismatch: features=${features.length}, scaler=${means.length}");
      return features;
    }

    List<double> scaled = [];
    for (int i = 0; i < features.length; i++) {
      scaled.add((features[i] - means[i]) / stds[i]);
    }
    return scaled;
  }
}