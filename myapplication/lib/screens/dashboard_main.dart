import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/profile.dart';
import 'package:frontend/screens/activity.dart';
import 'package:frontend/screens/notifications_screen.dart';
import 'package:frontend/models/health_data.dart';
import 'package:frontend/models/notification.dart' as app_models;
import 'package:frontend/services/health_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/WearOsService.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:frontend/helper/background_task_handler.dart';

class DashboardMain extends StatefulWidget {
  const DashboardMain({super.key});

  @override
  State<DashboardMain> createState() => _DashboardMainState();
}

class _DashboardMainState extends State<DashboardMain> {
  int _selectedIndex = 0;
  
  final GlobalKey<_DashboardContentState> _dashboardKey =
      GlobalKey<_DashboardContentState>();
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardContent(key: _dashboardKey),
      const ActivityScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1429),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: const Color(0xFF0F1429),
        selectedItemColor: const Color(0xFF4ECDC4),
        unselectedItemColor: Colors.white.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Stats',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.analytics),
          //   label: 'Stats',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  HealthData? _latestHealthData;
  final HealthConnectService _healthService = HealthConnectService();
  int _currentSteps = 0;
  double _currentOxygen = 0;
  double _currentSleep = 0;
  double _currentCalories = 0.0;
  double _currentHeartRate = 0;
  double _watchHeartRate = 0;
double _accelX = 0;
bool _isWatchConnected = false;
  bool _isLoading = true;
  int _notificationCount = 0;
  String _stepsDisplay = "0"; 
  int _lastSavedHR = 0;
  final User? user = FirebaseAuth.instance.currentUser;
  // late Stream<StepCount> _stepCountStream;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  // StreamSubscription<StepCount>? _stepSubscription;
  // StreamSubscription<StepCount>? _pedometerSubscription;
  // int _stepsAtStartOfSession = 0; // Angka dari Health Connect saat app dibuka
  int _pedometerBase = 0;
  double _totalCaloriesBurned = 0.0;
  double _currentCaloriesHC = 0.0;
DateTime? _lastUpdateTime;

  @override
@override
void initState() {
  super.initState();
  
  _initApp(); 
  // _initPedometerHP();
  // _initStepTracking();
  // _initHealthConnect();

  Future.delayed(Duration(seconds: 1), () {
    _initApp();
  });

  Timer.periodic(const Duration(minutes: 10), (timer){
    _healthService.syncHealthData();
    _initApp();
  });

  WearOsService().sensorStream.listen((data) {
    if (mounted) {
      final now = DateTime.now();
      
      double currentHR = data['hr'] ?? 0.0;
      double ax = data['ax'] ?? 0.0;
      double ay = data['ay'] ?? 0.0;
      double az = data['az'] ?? 0.0;

      // OTOMATIS: Jalankan Background Service AI jika data masuk
      // _startService(); 
      _startForegroundService();

      setState(() {
        _watchHeartRate = currentHR;
        _accelX = ax;
        _isWatchConnected = true;

        // --- LOGIKA HITUNG KALORI ---
        if (_lastUpdateTime != null) {
          double secondsElapsed = now.difference(_lastUpdateTime!).inMilliseconds / 1000.0;
          if (secondsElapsed > 0 && secondsElapsed < 10) { 
            double calPerSec = _calculateInstantCalories(currentHR, ax, ay, az);
            _totalCaloriesBurned += calPerSec * secondsElapsed;
          }
        }
        _lastUpdateTime = now;

        _latestHealthData = HealthData(
          hr: currentHR,
          ax: ax,
          ay: ay,
          az: az,
        );
      });

      // --- SIMPAN KE FIREBASE ---
      // Throttling: Simpan ke cloud setiap 5 detik agar hemat baterai & kuota
      if (now.second % 5 == 0 && currentHR > 0) {
        _saveToFirebase(_latestHealthData!);
      }

      // --- BACKUP LOKAL ---
      if (now.second % 30 == 0) _persistCalories(); 
    }
  });

  // 3. Mulai aktifkan koneksi ke jam tangan dengan sedikit delay
  Future.delayed(const Duration(seconds: 1), () {
    WearOsService().initListener();
  });
}

Future<void> _startForegroundService() async {
  if (!await FlutterForegroundTask.isRunningService) {
    await FlutterForegroundTask.startService(
      notificationTitle: 'Monitoring Emosi Aktif ✅',
      notificationText: 'AI sedang mendeteksi tingkat stres Anda...',
      callback: startCallback,
    );
  }
}
void _saveToFirebase(HealthData data) async {
  if (user != null) {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('health_logs')
          .add(data.toMap());
          
      // Atau update data ringkasan harian
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
            'last_steps': _currentSteps,
            'last_heart_rate': _watchHeartRate,
            'last_updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Gagal simpan ke Firebase: $e");
    }
  }
}
@override
void dispose() {
  // _bleSubcription?.cancel();
  // _stepSubscription?.cancel(); // Pastikan dimatikan agar hemat baterai
  super.dispose();
}

// void _initStepTracking() async {
//     // 1. Inisialisasi Listener Smartwatch (WearOsService)
//     WearOsService().initListener(); // Pastikan listener aktif
//     WearOsService().sensorStream.listen((data) {
//       if (mounted) {
//         setState(() {
//           // Ambil 'steps' dari Map yang dikirim WearOsService
//           _watchStepsToday = (data['steps'] ?? 0).toInt();
//           _calculateTotalSteps();
//         });
//       }
//     });

//     // 2. Inisialisasi Pedometer HP
//     // if (await Permission.activityRecognition.request().isGranted) {
//     //   Pedometer.stepCountStream.listen((StepCount event) async {
//     //     SharedPreferences prefs = await SharedPreferences.getInstance();
//     //     String today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD
        
//     //     // Ambil titik nol HP hari ini
//     //     int savedBase = prefs.getInt('phone_base_$today') ?? -1;

//     //     if (savedBase == -1) {
//     //       // Jika baru pertama kali buka hari ini, set base ke angka sensor saat ini
//     //       await prefs.setInt('phone_base_$today', event.steps);
//     //       savedBase = event.steps;
//     //     }

//     //     if (mounted) {
//     //       setState(() {
//     //         _phoneBaseSteps = savedBase;
//     //         _phoneStepsToday = event.steps - _phoneBaseSteps;
//     //         _calculateTotalSteps();
//     //       });
//     //     }
//     //   });
//     // }
//   }

  // void _calculateTotalSteps() {
  //   int total = _phoneStepsToday + _watchStepsToday;
  //   _stepsDisplay = total.toString();

  //   // Sinkronisasi ke Firestore agar ProfileScreen ikut update
  //   final uid = FirebaseAuth.instance.currentUser?.uid;
  //   if (uid != null) {
  //     FirebaseFirestore.instance.collection('users').doc(uid).set({
  //       'totalSteps': total,
  //       'lastUpdate': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //   }
  // }
  // // --- LOGIKA SENSOR HP (Pedometer) ---
  // void _initPedometerHP() async {
  //   if (await Permission.activityRecognition.request().isGranted) {
  //     Pedometer.stepCountStream.listen((StepCount event) async {
  //       SharedPreferences prefs = await SharedPreferences.getInstance();
  //       String today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD
        
  //       // Ambil titik nol langkah HP hari ini
  //       int savedBase = prefs.getInt('phone_base_$today') ?? -1;

  //       if (savedBase == -1) {
  //         await prefs.setInt('phone_base_$today', event.steps);
  //         savedBase = event.steps;
  //       }

  //       setState(() {
  //         _phoneBaseSteps = savedBase;
  //         _phoneStepsDay = event.steps - _phoneBaseSteps;
  //         _updateTotalAndSync();
  //       });
  //     });
  //   }
  // }

  // // --- GABUNGKAN & SIMPAN ---
  // void _updateTotalAndSync() {
  //   int totalSteps = _phoneStepsDay + _watchStepsDay;
  //   _stepsDisplay = totalSteps.toString();
  //   double distanceKm = totalSteps * 0.000762;

  //   // Kirim ke Firestore agar ProfileScreen ikut update
  //   if (_uid != null) {
  //     FirebaseFirestore.instance.collection('users').doc(_uid).set({
  //       'steps': totalSteps,
  //       'distance' : distanceKm,
  //       'calories' : _totalCaloriesBurned,
  //       'lastUpdate': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //   }
  // }

Future<void> _initApp() async {
  
  if (!mounted) return;
  print("🟡FUNGSI _INITAPP DIJALANKAN");
  setState(() => _isLoading = true);

  try{
    final prefs = await SharedPreferences.getInstance();
  _totalCaloriesBurned = prefs.getDouble('saved_calories') ?? 0.0;
  
  await _handlePermissions();

    // ✅ Abaikan return value, langsung fetch
    await _healthService.requestPermissions();
    final data = await _healthService.fetchTodayData();

    if (mounted) {
      print("🔥 Steps: ${data['steps']}, Sleep: ${data['sleep']}, Oxygen: ${data['oxygen']}");
      setState(() {
        _currentSteps = data['steps'] ?? 0;
        _currentSleep = (data['sleep'] ?? 0.0).toDouble();
        _currentOxygen = (data['oxygen'] ?? 0.0).toDouble();
        _currentCaloriesHC = (data['calories'] ?? 0.0).toDouble();
        _isLoading = false;
      });
    }
  } catch (e) {
    debugPrint("Error in _initApp: $e");
    if (mounted) setState(() => _isLoading = false);
  } 
  
  // 2. Baru jalankan pedometer SETELAH data awal didapat
  // _initRealTimePedometer();

  // if (mounted) setState(() => _isLoading = false);
}

// void _initRealTimePedometer() {
//   _pedometerSubscription = Pedometer.stepCountStream.listen(
//     (StepCount event) {
//       if (mounted) {
//         setState(() {
//           if (_pedometerBase == 0) {
//             _pedometerBase = event.steps;
//           }

//           int stepsSinceAppOpen = event.steps - _pedometerBase;

//           // LOGIKA ANTI-NOL:
//           if (_stepsAtStartOfSession > 0) {
//             // Jika Health Connect ada isinya, gunakan Hybrid
//             _currentSteps = _stepsAtStartOfSession + stepsSinceAppOpen;
//           } else {
//             // JIKA HEALTH CONNECT 0, tampilkan saja langkah dari sensor HP langsung
//             // Supaya user tidak melihat angka 0 terus menerus
//             _currentSteps = event.steps; 
//           }
          
//           debugPrint("Langkah di Layar: $_currentSteps");
//         });
//       }
//     },
//   );
// }

// Masukkan di dalam class _DashboardContentState

double _calculateInstantCalories(double hr, double ax, double ay, double az) {
  if (hr < 45) return 0.0; // Anggap tidak ada aktivitas jika HR sangat rendah

  // Rumus dasar (Laki-laki sebagai default, idealnya ambil dari profil user)
  // Menghasilkan kkal/menit
  double weight = 70.0;
  int age = 25;
  double caloriesPerMin = ((-55.0969 + (0.6309 * hr) + (0.1988 * weight) + (0.2017 * age)) / 4.184);

  // Gunakan magnitude akselerometer untuk faktor intensitas
  double magnitude = math.sqrt(ax * ax + ay * ay + az * az);
  double intensityFactor = 1.0;
  if (magnitude > 15.0) intensityFactor = 1.5; // Berlari
  else if (magnitude > 11.0) intensityFactor = 1.2; // Berjalan

  return (caloriesPerMin / 60) * intensityFactor; // Kembalikan nilai per detik
}

// Fungsi untuk menyimpan ke SharedPreferences (Persistence)
Future<void> _persistCalories() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('saved_calories', _totalCaloriesBurned);
  await prefs.setString('last_cal_update', DateTime.now().toIso8601String());
}

Future<void> _handlePermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
    Permission.activityRecognition, 
    Permission.sensors,
  ].request();
  
  print("Permission Status: $statuses");
}

  void _loadNotificationCount() {
    final notifications =
        app_models.NotificationService.getSampleNotifications();
    setState(() {
      _notificationCount =
          app_models.NotificationService.getUnreadCount(notifications);
    });
  }

// with AutomaticKeepAliveClientMixin {

//   @override
//   bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // Main Stats Grid
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    //     // Quick Stats
                        _buildQuickStats(),
                        const SizedBox(height: 24),

                        // Heart Rate Section
                        _buildHeartRateCard(),
                        const SizedBox(height: 16),

                        // Activity Stats
                        // _buildActivityStats(),
                        const SizedBox(height: 16),

                        // Progress Bars
                        _buildProgressBars(),
                        const SizedBox(height: 16),

                        // Recent Activity
                        _buildRecentActivity(),
                    //   ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
  var hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Good Morning';
  } else if (hour < 17) {
    return 'Good Afternoon';
  } else if (hour < 20) {
    return 'Good Evening';
  } else {
    return 'Good Night';
  }
}

  Widget _buildHeader() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            // Di dalam Widget _buildHeader()
StreamBuilder(
  stream: FirebaseDatabase.instance.ref("users/${currentUser?.uid}").onValue,
  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
    if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
      final data = Map<String, dynamic>.from(
          snapshot.data!.snapshot.value as Map);
      return Text(
        data['username'] ?? "User",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return const Text("User", style: TextStyle(color: Colors.white));
  },
),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            ).then((_) {
              // Refresh notification count when returning
              _loadNotificationCount();
            });
          },
          child: Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F3A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications,
                  color: Colors.white54,
                  size: 28,
                ),
              ),
              // Badge untuk jumlah notifikasi
              if (_notificationCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0A0E27),
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _notificationCount > 9 ? '9+' : '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final heartRate = _latestHealthData?.hr ?? 0.0;
    final motionX = _latestHealthData?.ax ?? 0.0;
    // final heartRate =
    
        // _latestHealthData?.heartRate ?? _todayStats?.avgHeartRate.toInt() ?? 0;
    // final steps = _latestHealthData?.steps ?? _todayStats?.totalSteps ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            value: _currentCaloriesHC.toStringAsFixed(0),
            label: 'Calories',
            color: const Color(0xFFFF6B6B),
            bgColor: const Color(0xFFFF6B6B).withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
  child: _buildStatCard(
    icon: Icons.directions_walk, // Ikon orang berjalan
    value: NumberFormat.decimalPattern().format(_currentSteps), // Mengambil variabel langkah real-time
    label: 'Steps Today',
    color: const Color(0xFF4ECDC4),
    bgColor: const Color(0xFF4ECDC4).withOpacity(0.1),
  ),
),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

void _showStressDialog(String label) {
  showDialog(
    context: context,
    barrierDismissible: false, // User harus berinteraksi
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text("Peringatan Stres", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          "Model AI kami mendeteksi tingkat stres yang tinggi pada Anda. Ingin melakukan latihan pernapasan sekarang?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Nanti Saja", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              // Arahkan ke fitur relaksasi/napas
            },
            child: Text("Mulai Relaksasi"),
          ),
        ],
      );
    },
  );
}
  void _showAddWaterDialog(BuildContext context) {
  final TextEditingController waterController = TextEditingController();
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1F3A),
      title: const Text('Tambah Minum', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: waterController,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Masukkan jumlah (ml)',
          hintStyle: TextStyle(color: Colors.white54),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (waterController.text.isNotEmpty && uid != null) {
              double addedLiters = double.parse(waterController.text) / 1000;
              
              // Update ke Firestore: Menambah nilai yang sudah ada
              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                'waterIntake': FieldValue.increment(addedLiters),
              });

              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

Widget _buildHeartRateCard() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          const Color(0xFFFF6B6B),
          const Color(0xFFFF8E8E),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Heart Rate',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: _isWatchConnected
                        ? Colors.greenAccent
                        : Colors.red,
                    size: 8,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isWatchConnected ? 'Watch Live' : 'Live',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // STREAM BUILDER (HANYA 1)
        StreamBuilder(
          stream: FirebaseDatabase.instance.ref('health_metrics').onValue,
          builder: (context, snapshot) {
            int displayHR = _lastSavedHR;

            if (snapshot.hasData &&
                snapshot.data!.snapshot.value != null) {
              try {
                final data = Map<dynamic, dynamic>.from(
                    snapshot.data!.snapshot.value as Map);

                int currentHR = data['heart_rate'] ?? 0;

                if (currentHR > 0) {
                  _lastSavedHR = currentHR;
                  displayHR = currentHR;
                }
              } catch (e) {
                print("Error parsing HR: $e");
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEART RATE TEXT
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _watchHeartRate <= 0 
                        ? '--' 
                        : _watchHeartRate.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        'bpm',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // MINI STATS
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          double waterIntake = 0.0;

                          if (snapshot.hasData &&
                              snapshot.data!.exists) {
                            var data = snapshot.data!.data()
                                as Map<String, dynamic>;
                            waterIntake =
                                (data['waterIntake'] ?? 0.0).toDouble();
                          }

                          return InkWell(
                            onTap: () =>
                                _showAddWaterDialog(context),
                            borderRadius: BorderRadius.circular(12),
                            child: _buildMiniStat(
                              'Water',
                              '${waterIntake.toStringAsFixed(1)}L',
                              Icons.water_drop,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMiniStat(
                        'Sleep',
                        '${_currentSleep.toStringAsFixed(1)}h',
                        Icons.single_bed_sharp,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBars() {
    return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .snapshots(),
    builder: (context, snapshot) {
      double waterIntake = 0.0;
      if (snapshot.hasData && snapshot.data!.exists) {
        final data = snapshot.data!.data() as Map<String, dynamic>;
        waterIntake = (data['waterIntake'] ?? 0.0).toDouble();
      }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Goals',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressItem(
            'Steps',
            _currentSteps,
            // _todayStats?.totalSteps ?? _latestHealthData?.steps ?? 0,
            10000,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildProgressItem(
            'Calories',
            _currentCaloriesHC
            // (_todayStats?.totalCalories ?? _latestHealthData?.calories ?? 0)
                .toInt(),
            500,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildProgressItem(
            'Sleep',
            (_currentSleep * 60).toInt(),
            480,
            // , // 8 hours in minutes
            Colors.green,
            displayValue: '${_currentSleep.toStringAsFixed(1)}h/8h'
          ),
          const SizedBox(height: 16),
          _buildProgressItem(
            'Water',
            (waterIntake * 1000).toInt(),
            2,
            Colors.lightBlue,
            displayValue: '${waterIntake.toStringAsFixed(1)}L / 2L',
          )
        ],
      ),
    );
    },
    );
  }

  Widget _buildProgressItem(
      String label, int current, int target, Color color,
      {String suffix = '', String? displayValue}) {
    final progress = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              '$current / $target',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActivityItem(
          'Morning Run',
          '30 minutes • 3.2 km',
          Icons.directions_run,
          const Color(0xFF4ECDC4),
          '09:00 AM',
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          'Cycling',
          '45 minutes • 8.5 km',
          Icons.directions_bike,
          const Color(0xFF9B59B6),
          '11:30 AM',
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          'Walking',
          '25 minutes • 1.8 km',
          Icons.directions_walk,
          const Color(0xFF3498DB),
          '02:15 PM',
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String time,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}