import 'dart:isolate';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
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
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      print('ℹ️ WidgetsFlutterBinding initialized in background task');
      print('🔄 onStart: mencoba load interpreter dari asset');
      Uint8List? modelBuffer;
      final modelCandidates = [
        'assets/model_emotion_lite(4).tflite',
        'model_emotion_lite(4).tflite',
        'assets/model_emotion_lite.tflite',
        'model_emotion_lite.tflite',
      ];
      for (final candidate in modelCandidates) {
        try {
          final modelBytes = await rootBundle.load(candidate);
          print(
              'ℹ️ rootBundle loaded model bytes from "$candidate": ${modelBytes.lengthInBytes}');
          modelBuffer = modelBytes.buffer.asUint8List();
          break;
        } catch (assetErr) {
          print(
              '⚠️ rootBundle failed to load model path "$candidate": $assetErr');
        }
      }

      try {
        if (modelBuffer != null) {
          _interpreter = Interpreter.fromBuffer(modelBuffer);
          print('ℹ️ Loaded interpreter from buffer');
        } else {
          print('⚠️ modelBuffer null, mencoba Interpreter.fromAsset fallback');
          for (final candidate in modelCandidates) {
            try {
              _interpreter = await Interpreter.fromAsset(candidate);
              print('ℹ️ Loaded interpreter from asset "$candidate"');
              break;
            } catch (assetErr) {
              print(
                  '⚠️ Interpreter.fromAsset failed for "$candidate": $assetErr');
            }
          }
        }
      } catch (e, stack) {
        print('❌ Interpreter buffer load failed: $e');
        print(stack);
        _interpreter = null;
      }

      // Load scaler JSON with fallback paths
      String jsonString = '';
      try {
        jsonString = await rootBundle.loadString('scaler_params(4).json');
        print('ℹ️ Loaded scaler_params(4).json');
      } catch (rs1) {
        print('⚠️ rootBundle load try #1 failed: $rs1');
        try {
          jsonString =
              await rootBundle.loadString('assets/scaler_params(4).json');
          print('ℹ️ Loaded assets/scaler_params(4).json');
        } catch (rs2) {
          print('❌ Scaler JSON load failed (both paths): $rs2');
          jsonString = '';
        }
      }

      if (jsonString.isNotEmpty) {
        Map<String, dynamic> scaler = jsonDecode(jsonString);
        _mean = List<double>.from(scaler['mean'].map((x) => x.toDouble()));
        _std = List<double>.from(scaler['std'].map((x) => x.toDouble()));
      }

      if (_interpreter != null && _mean != null && _std != null) {
        print("✅ AI Model & Scaler Berhasil Dimuat");
        print("✅ Jumlah fitur — mean: ${_mean?.length}, std: ${_std?.length}");
      } else {
        print(
            "❌ AI Load incomplete: interpreter=${_interpreter != null}, mean=${_mean != null}, std=${_std != null}");
        final prefsErr = await SharedPreferences.getInstance();
        await prefsErr.setString('last_ai_error',
            'Load incomplete: interpreter=${_interpreter != null}, mean=${_mean != null}, std=${_std != null}');
      }
    } catch (e, stack) {
      print("❌ AI Load Error: $e");
      print(stack);
      final prefsErr = await SharedPreferences.getInstance();
      await prefsErr.setString('last_ai_error', e.toString());
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    print("🔁 onRepeatEvent: ${DateTime.now()}");

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    String? featureString = prefs.getString('latest_features');

    print("🔍 featureString null? ${featureString == null}");
    print("🔍 interpreter null? ${_interpreter == null}");

    if (featureString == null || _interpreter == null) {
      print("⏳ Menunggu data...");
      return;
    }

    try {
      List<double> rawInput = List<double>.from(jsonDecode(featureString));
      print("🔍 rawInput length: ${rawInput.length}");

      if (rawInput.length != 13) {
        print("⚠️ Fitur tidak valid: ${rawInput.length}, expected 13");
        return;
      }

      // Normalisasi
      List<double> inputScaled = [];
      for (int i = 0; i < 13; i++) {
        inputScaled.add((rawInput[i] - _mean![i]) / _std![i]);
      }

      // Shape [1, 1, 13] untuk GRU
      var input3D = [
        [inputScaled]
      ];
      var output = List.filled(3, 0.0).reshape([1, 3]);
      _interpreter!.run(input3D, output);

      List<double> probs = List<double>.from(output[0]);
      print("---------------------------------------");
      print("AI ANALISIS:");
      print("Baseline : ${(probs[0] * 100).toStringAsFixed(2)}%");
      print("Stress   : ${(probs[1] * 100).toStringAsFixed(2)}%");
      print("Amusement: ${(probs[2] * 100).toStringAsFixed(2)}%");

      int label = _getMaxIndex(probs);
      String status = label == 1
          ? "Stress"
          : label == 2
              ? "Happy"
              : "Normal";

      // Selalu simpan status terbaru (untuk polling UI)
      final String normalPct = (probs[0] * 100).toStringAsFixed(1);
      final String stressPct = (probs[1] * 100).toStringAsFixed(1);
      final String happyPct = (probs[2] * 100).toStringAsFixed(1);

      // Simpan hasil prediksi terbaru untuk dibaca UI via polling
      await prefs.setString('last_ai_status', status);
      await prefs.setString(
          'last_ai_probs',
          jsonEncode({
            'normal': normalPct,
            'stress': stressPct,
            'happy': happyPct,
          }));
      await prefs.setString(
          'last_ai_timestamp', DateTime.now().toIso8601String());

      // Hanya buat notifikasi jika status berubah
      if (status != _lastStatus) {
        print("🔄 Status: $_lastStatus → $status");
        _lastStatus = status;

        final String probStr =
            'Baseline: $normalPct% | Stres: $stressPct% | Amusement: $happyPct%';

        String notifTitle, notifText, notifType;
        if (status == "Stress") {
          notifTitle = '⚠️ Peringatan Stres Terdeteksi!';
          notifText =
              'Detak jantung menunjukkan indikasi stres tinggi. Yuk, istirahat sejenak.\n$probStr';
          notifType = 'alert';
        } else if (status == "Happy") {
          notifTitle = 'Mood Anda Sangat Baik! 🎉';
          notifText =
              'Kondisi emosi terpantau positif. Pertahankan energi ini!\n$probStr';
          notifType = 'achievement';
        } else {
          notifTitle = 'Kondisi Tubuh Stabil';
          notifText = 'Status emosi terpantau normal.\n$probStr';
          notifType = 'health';
        }

        // Update notifikasi di status bar
        FlutterForegroundTask.updateService(
          notificationTitle: notifTitle,
          notificationText: notifText,
        );

        // Simpan ke daftar notifikasi
        final prefs2 = await SharedPreferences.getInstance();
        final newNotif = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'title': notifTitle,
          'message': notifText,
          'type': notifType,
          'timestamp': DateTime.now().toIso8601String(),
          'is_read': false,
        };
        final String? savedData = prefs2.getString('saved_notifications');
        List<dynamic> existingList =
            savedData != null ? jsonDecode(savedData) : [];
        existingList.insert(0, newNotif);
        if (existingList.length > 50)
          existingList = existingList.sublist(0, 50);
        await prefs2.setString('saved_notifications', jsonEncode(existingList));
        print("✅ Notifikasi tersimpan: $notifTitle");
      }
    } catch (e, stack) {
      print("❌ Error prediksi: $e");
      print("❌ Stack: $stack");
    }
  }

  int _getMaxIndex(List<double> probs) {
    int maxIdx = 0;
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > probs[maxIdx]) maxIdx = i;
    }
    return maxIdx;
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    _interpreter?.close();
    print("🛑 Background task destroyed");
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyBackgroundTaskHandler());
}
