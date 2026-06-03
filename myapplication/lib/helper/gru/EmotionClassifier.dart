import 'dart:convert'; 
import 'package:flutter/services.dart'; 
import 'package:tflite_flutter/tflite_flutter.dart'; 
import 'package:frontend/helper/gru/EmotionPreprocessor.dart'; // Import file preprocessor tadi

class EmotionClassifier {
  Interpreter? _interpreter;
  Map<String, dynamic>? _scaler;

  Future<void> init() async {
    _interpreter = await Interpreter.fromAsset('assets/model_emotion_lite(4).tflite');
    String scalerString = await rootBundle.loadString('assets/scaler_params(4).json');
    _scaler = jsonDecode(scalerString);
  }

  String predict(List<double> hr, List<double> ax, List<double> ay, List<double> az) {
    if (_interpreter == null || _scaler == null) return "Model belum siap";

    // 1. Ekstraksi 12 Fitur
    List<double> rawFeatures = EmotionPreprocessor.extractFeatures(hr,ax,ay,az);
    List<double> input = EmotionPreprocessor.normalize(rawFeatures, _scaler!);

    var input3D = [[ input ]];

    var output = List.filled(3, 0.0).reshape([1, 3]);
    _interpreter!.run(input3D, output);

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