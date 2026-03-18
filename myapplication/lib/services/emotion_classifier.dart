import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class EmotionClassifier {
  Interpreter? _interpreter;
  Map<String, dynamic>? _scaler;

  Future<void> init() async {
    // Muat model TFLite
    _interpreter = await Interpreter.fromAsset('model_emotion_lite.tflite');
    
    // Muat parameter scaler (mean & std)
    String jsonString = await rootBundle.loadString('assets/scaler_params.json');
    _scaler = jsonDecode(jsonString);
  }

  String predict(List<double> inputData) {
    if (_interpreter == null || _scaler == null) return "Unknown";

    // 1. Preprocessing: Standarisasi data menggunakan mean & std dari JSON
    List<double> mean = List<double>.from(_scaler!['mean']);
    List<double> std = List<double>.from(_scaler!['std']);
    
    List<double> scaledInput = [];
    for (int i = 0; i < inputData.length; i++) {
      scaledInput.add((inputData[i] - mean[i]) / std[i]);
    }

    // 2. Jalankan Inshere/Prediksi
    var output = List.filled(1 * 3, 0.0).reshape([1, 3]); // Sesuaikan jumlah class (misal: 3 class di WESAD)
    _interpreter!.run(scaledInput.reshape([1, inputData.length]), output);

    // 3. Ambil hasil dengan probabilitas tertinggi
    int resultIndex = 0;
    double maxProb = -1.0;
    for (int i = 0; i < output[0].length; i++) {
      if (output[0][i] > maxProb) {
        maxProb = output[0][i];
        resultIndex = i;
      }
    }

    // Sesuaikan dengan label training Anda (Contoh: 0: Baseline, 1: Stress, 2: Amusement)
    if (resultIndex == 1) return "Stress";
    if (resultIndex == 2) return "Amusement";
    return "Normal";
  }
}