import 'dart:convert'; // Untuk jsonDecode
import 'package:flutter/services.dart'; // Untuk rootBundle
import 'package:tflite_flutter/tflite_flutter.dart'; // Pastikan package ini ada di pubspec.yaml
import 'package:frontend/helper/EmotionPreprocessor.dart'; // Import file preprocessor tadi

class EmotionClassifier {
  Interpreter? _interpreter;
  Map<String, dynamic>? _scaler;

  Future<void> init() async {
    // Muat model dan scaler
    _interpreter = await Interpreter.fromAsset('assets/model_emotion_lite.tflite');
    String scalerString = await rootBundle.loadString('assets/scaler_params.json');
    _scaler = jsonDecode(scalerString);
  }

  String predict(List<double> hr, List<double> ax, List<double> ay, List<double> az) {
    if (_interpreter == null || _scaler == null) return "Model belum siap";

    // 1. Ekstraksi 12 Fitur
    List<double> rawFeatures = EmotionPreprocessor.extractFeatures(hr,ax,ay,az);
    List<double> input = EmotionPreprocessor.normalize(rawFeatures, _scaler!);

    var output = List.filled(3, 0.0).reshape([1, 3]);
    _interpreter!.run([input], output);

    // 4. Ambil Label Terbesar
    List<double> results = List<double>.from(output[0]);
    int maxIdx = 0;
    double maxVal = results[0];
    for (int i = 1; i < results.length; i++) {
      if (results[i] > maxVal) {
        maxVal = results[i];
        maxIdx = i;
      }
    }
    
    List<String> labels = ['Baseline', 'Stress', 'Amusement'];
    return labels[maxIdx];
  }
}