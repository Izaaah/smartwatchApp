import 'dart:isolate';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyBackgroundTaskHandler extends TaskHandler {
  Interpreter? _interpreter;
  List<double>? _mean;
  List<double>? _std;
  String? _lastStatus;

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    try {
      // Muat model - Gunakan path yang sesuai dengan pubspec.yaml
      _interpreter = await Interpreter.fromAsset('assets/model_emotion_lite.tflite');
      
      // Muat parameter scaler untuk normalisasi
      String jsonString = await rootBundle.loadString('assets/scaler_params.json');
      Map<String, dynamic> scaler = jsonDecode(jsonString);
      
      _mean = List<double>.from(scaler['mean'].map((x) => x.toDouble()));
      _std = List<double>.from(scaler['std'].map((x) => x.toDouble()));
      
      print("AI Model & Scaler Berhasil Dimuat");
    } catch (e) {
      print("AI Load Error: $e");
    }
  }

  // @override
  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    final prefs = await SharedPreferences.getInstance();
    String? featureString = prefs.getString('latest_features');
    
    if (featureString != null && _interpreter != null) {
      try {
        List<double> rawInput = List<double>.from(jsonDecode(featureString));

        if (rawInput.length != 12) {
          print("⚠️ Jumlah fitur tidak valid: ${rawInput.length}, expected 12");
          return;
        }
        // 1. Normalisasi
        List<double> inputScaled = [];
        for (int i = 0; i < 12; i++) {
          inputScaled.add((rawInput[i] - _mean![i]) / _std![i]);
        }

        // 2. Prediksi
        var output = List.filled(1 * 3, 0.0).reshape([1, 3]);
        _interpreter!.run(inputScaled.reshape([1, 12]), output);

        // --- BAGIAN DEBUG UNTUK SIDANG/TESTING ---
        List<double> probs = List<double>.from(output[0]);
        print("---------------------------------------");
        print("AI ANALISIS:");
        print("Probabilitas - Normal (0): ${(probs[0] * 100).toStringAsFixed(2)}%");
        print("Probabilitas - STRES (1) : ${(probs[1] * 100).toStringAsFixed(2)}%");
        print("Probabilitas - Happy (2) : ${(probs[2] * 100).toStringAsFixed(2)}%");
        // ---------------------------------------

        int label = _getMaxIndex(output[0]);
        String status = (label == 1) ? "Stress" : "Normal";
        
        if (status != _lastStatus) {
          print("🔄 Status Berubah: $_lastStatus -> $status");
          _lastStatus = status;

          String notifTitle;
          String notifText;

          if (status == "Stress") {
            notifTitle = '⚠️ Terdeteksi Stres';
            notifText = 'Tingkat stes tinggi (${(probs[1] * 100).toStringAsFixed(1)}%). Coba istirahat sejenak.';
          } else if (status == "Happy") {
            notifTitle = 'Mood Anda Baik!';
            notifText = 'Kondisi emosi terpantau positif.';
          } else {
            notifTitle = 'Kondisi Stabil';
            notifText = 'Emosi terpantau normal.';
          }

          FlutterForegroundTask.updateService(
            notificationTitle: notifTitle,
            notificationText: notifText,
          );
        sendPort?.send(status);
        }
        // FlutterForegroundTask.updateService(
        //   notificationTitle: status == "Stress" ? '⚠️ Terdeteksi Stres' : 'Kondisi Stabil ✅',
        //   notificationText: status == "Stress" 
        //     ? 'Tingkat stres tinggi (${(probs[1] * 100).toStringAsFixed(1)}%)' 
        //     : 'Emosi terpantau normal.',
        // );

      } catch (e) {
        print("Error saat prediksi: $e");
      }
    } else {
      print("Menunggu data window 60 detik penuh...");
    }
  }

  int _getMaxIndex(List<double> probs) {
    int maxIdx = 0;
    double maxVal = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxVal) {
        maxVal = probs[i];
        maxIdx = i;
      }
    }
    return maxIdx;
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    _interpreter?.close();
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyBackgroundTaskHandler());
}