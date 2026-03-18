import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/services/WearOsService.dart';

class DataCollectionPage extends StatefulWidget {
  final String username;
  final String gender;
  final String weight;

  const DataCollectionPage({
    super.key,
    required this.username,
    required this.gender,
    required this.weight,
  });

  @override
  _DataCollectionPageState createState() => _DataCollectionPageState();
}

class _DataCollectionPageState extends State<DataCollectionPage> {
  String _selectedActivity = "Diam/Santai";
  bool _isLogging = false;
  int _totalDataCount = 0; // Sekarang akan menghitung jumlah sesi
  int _t = 0;

  Timer? _timer;
  int _secondsRemaining = 300;
  List<Map<String, dynamic>> _localSamples = [];

  final List<String> _activities = [
    "Diam/Santai",
    "Stres/Tegang",
    "Berjalan",
    "Motoran",
    "Sepedahan"
  ];

  @override
  void initState() {
    super.initState();
    _fetchTotalData();
    WearOsService().onData = _saveToLocalMemory;
    WearOsService().initListener();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Mengambil jumlah total sesi yang sudah pernah disimpan oleh user ini
  Future<void> _fetchTotalData() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('raw_data_skripsi')
          .where('username', isEqualTo: widget.username)
          .get();

      if (mounted) {
        setState(() {
          _totalDataCount = querySnapshot.docs.length;
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  void _startTimer() {
    _secondsRemaining = 300;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _stopRecording(isAutoStop: true);
          }
        });
      }
    });
  }

  void _saveToLocalMemory(Map<String, double> data) {
    if (!_isLogging) return;
    _t++;
    _localSamples.add({
      't': _t,
      'hr': data['hr'],
      'ax': data['ax'],
      'ay': data['ay'],
      'az': data['az'],
      'steps': data['steps'],
      'ts': Timestamp.now(),
    });
  }

  void _stopRecording({bool isAutoStop = false}) async {
    _timer?.cancel();
    if (!mounted) return;

    setState(() {
      _isLogging = false;
      WearOsService().isLogging = false;
    });

    // Tampilkan Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (_localSamples.isNotEmpty) {
        final firestore = FirebaseFirestore.instance;

        // MENGUBAH LOGIKA: Simpan sebagai 1 dokumen berisi Array sensor_data
        await firestore.collection('raw_data_skripsi').add({
          'username': widget.username,
          'gender': widget.gender,
          'weight': widget.weight,
          'label': _selectedActivity,
          'start_time': _localSamples.first['ts'],
          'end_time': Timestamp.now(),
          'total_samples': _localSamples.length,
          'sensor_data': _localSamples, // Seluruh data masuk ke sini
        }).timeout(const Duration(minutes: 1));
      }

      _localSamples = [];
      _t = 0;

      if (mounted) {
        Navigator.pop(context); // Tutup loading
        _fetchTotalData();
        _showSuccessDialog(isAutoStop);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showWarning("Gagal mengunggah: $e. Coba gunakan WiFi yang lebih stabil.");
    }
  }

  void _showSuccessDialog(bool isAutoStop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAutoStop ? "Waktu Habis!" : "Selesai"),
        content: const Text("Data sesi berhasil disimpan ke Firestore."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logging: ${widget.username}"),
        backgroundColor: _isLogging ? Colors.red.shade400 : Colors.blue.shade400,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              color: Colors.amber.shade100,
              child: ListTile(
                leading: const Icon(Icons.analytics, color: Colors.amber),
                title: const Text("Total Sesi Tersimpan",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("$_totalDataCount",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            _buildTimerDisplay(),
            const SizedBox(height: 20),
            _buildActivityDropdown(),
            const SizedBox(height: 20),
            _buildControlButton(),
            const SizedBox(height: 20),
            const Divider(),
            _buildRealtimeMonitor(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER (TIDAK BERUBAH) ---

  Widget _buildTimerDisplay() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: _isLogging ? Colors.red.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(_isLogging ? "SISA WAKTU REKAMAN" : "DURASI REKAMAN"),
          Text(
            "${(_secondsRemaining ~/ 60)}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: _isLogging ? Colors.red : Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedActivity,
      decoration: const InputDecoration(
          labelText: "Pilih Aktivitas", border: OutlineInputBorder()),
      items: _activities
          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
          .toList(),
      onChanged:
          _isLogging ? null : (val) => setState(() => _selectedActivity = val!),
    );
  }

  Widget _buildControlButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: _isLogging ? Colors.red : Colors.green),
        onPressed: () {
          if (!_isLogging) {
            setState(() {
              _localSamples = [];
              _t = 0;
              _isLogging = true;
              WearOsService().isLogging = true;
            });
            _startTimer();
          } else {
            _stopRecording();
          }
        },
        child: Text(_isLogging ? "BERHENTI SEKARANG" : "MULAI REKAM (5 MENIT)",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRealtimeMonitor() {
    return Expanded(
      child: StreamBuilder<Map<String, double>>(
        stream: WearOsService().sensorStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: Text("Menunggu data dari jam..."));
          final data = snapshot.data!;
          return ListView(
            children: [
              ListTile(
                  title: const Text("Detak Jantung"),
                  trailing: Text("${data['hr']?.toInt()} BPM")),
              ListTile(
                  title: const Text("Akselerometer X"),
                  trailing: Text("${data['ax']?.toStringAsFixed(2)}")),
              ListTile(
                  title: const Text("Akselerometer Y"),
                  trailing: Text("${data['ay']?.toStringAsFixed(2)}")),
              ListTile(
                  title: const Text("Akselerometer Z"),
                  trailing: Text("${data['az']?.toStringAsFixed(2)}")),
            ],
          );
        },
      ),
    );
  }

  void _showWarning(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Peringatan"),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }
}