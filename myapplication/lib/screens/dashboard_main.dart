import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/profile.dart';
import 'package:frontend/screens/stats.dart';
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
import 'package:frontend/helper/gru/background_task_handler.dart';

typedef StressBannerCallback = void Function(String stressLevel, Map probs);

// ═══════════════════════════════════════════════════════════
// DASHBOARD MAIN (Shell + Banner + Bottom Nav)
// ═══════════════════════════════════════════════════════════
class DashboardMain extends StatefulWidget {
  const DashboardMain({super.key});

  @override
  State<DashboardMain> createState() => _DashboardMainState();
}

class _DashboardMainState extends State<DashboardMain>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _showStressBanner = false;
  String _stressBannerLevel = 'Stress';
  Map _stressBannerProbs = {};
  String? _lastAlertId; // ✅ Track alert ID untuk mencegah duplicate
  Timer? _pollingTimer; // ✅ Polling timer

  late AnimationController _bannerAnimController;
  late Animation<Offset> _bannerSlideAnim;
  late Animation<double> _bannerFadeAnim;

  final GlobalKey<_DashboardContentState> _dashboardKey =
      GlobalKey<_DashboardContentState>();
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _bannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bannerSlideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bannerAnimController,
      curve: Curves.easeOutBack,
    ));
    _bannerFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bannerAnimController, curve: Curves.easeIn),
    );

    _screens = [
      DashboardContent(
        key: _dashboardKey,
        onStressDetected: _triggerStressBanner,
      ),
      const StatsScreen(),
      const ActivityScreen(),
      const ProfileScreen(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _startForegroundService();
      print('🟢 initState: starting polling');
      _startPolling(); // ✅ Mulai polling setelah service start
      // Also check AI status once immediately so UI updates without waiting
      _checkAiStatusOnce();
    });
  }

  // ─── Foreground Service ──────────────────────────────────
  Future<void> _startForegroundService() async {
    print("🚀 _startForegroundService DIPANGGIL");

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'emotion_monitoring',
        channelName: 'Emotion Monitoring',
        channelDescription: 'AI monitoring emosi berjalan di background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 10000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );

    if (!await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Monitoring Emosi Aktif ✅',
        notificationText: 'AI sedang mendeteksi tingkat stres Anda...',
        callback: startCallback,
      );
    }

    bool isRunning = await FlutterForegroundTask.isRunningService;
    print("🔍 Service running: $isRunning");
  }

  // ─── Polling SharedPreferences (ganti receivePort) ───────
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      final String? lastAiStatus = prefs.getString('last_ai_status');
      final String? lastAiProbs = prefs.getString('last_ai_probs');
      final String? lastAiTimestamp = prefs.getString('last_ai_timestamp');

      print(
          '▶ Poll tick: _lastAlertId=$_lastAlertId last_ai_status=$lastAiStatus last_ai_timestamp=$lastAiTimestamp');
      if (lastAiProbs != null) print('▶ last_ai_probs=$lastAiProbs');

      if (lastAiStatus == 'Stress' &&
          lastAiProbs != null &&
          lastAiTimestamp != null) {
        if (lastAiTimestamp != _lastAlertId) {
          _lastAlertId = lastAiTimestamp;
          print(
              '🔔 AI status baru terdeteksi (poll): $lastAiStatus @ $lastAiTimestamp');
          try {
            final Map<String, dynamic> probs = jsonDecode(lastAiProbs);
            if (mounted) {
              _triggerStressBanner(
                  'Stress',
                  {
                    'stress': probs['stress']?.toString() ?? '0',
                    'normal': probs['normal']?.toString() ?? '0',
                    'happy': probs['happy']?.toString() ?? '0',
                  },
                  autoDissmiss: false);
            }
          } catch (e) {
            print('❌ Error decode last_ai_probs: $e');
          }
        }
      }
    });
  }

  // Immediate one-time check to update UI right after init
  Future<void> _checkAiStatusOnce() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final String? lastAiStatus = prefs.getString('last_ai_status');
    final String? lastAiProbs = prefs.getString('last_ai_probs');
    final String? lastAiTimestamp = prefs.getString('last_ai_timestamp');
    print(
        '🔎 One-time AI check: status=$lastAiStatus timestamp=$lastAiTimestamp');
    if (lastAiProbs != null) print('🔎 one-time probs=$lastAiProbs');

    if (lastAiStatus == 'Stress' &&
        lastAiProbs != null &&
        lastAiTimestamp != null) {
      if (lastAiTimestamp != _lastAlertId) {
        _lastAlertId = lastAiTimestamp;
        try {
          final Map<String, dynamic> probs = jsonDecode(lastAiProbs);
          if (mounted) {
            _triggerStressBanner(
                'Stress',
                {
                  'stress': probs['stress']?.toString() ?? '0',
                  'normal': probs['normal']?.toString() ?? '0',
                  'happy': probs['happy']?.toString() ?? '0',
                },
                autoDissmiss: false);
          }
        } catch (e) {
          print('❌ Error decode one-time last_ai_probs: $e');
        }
      }
    }
  }

  String _extractProb(String message, String label) {
    final match = RegExp('$label:\\s*([\\d.]+)%').firstMatch(message);
    return match?.group(1) ?? '0';
  }

  // ─── Banner ──────────────────────────────────────────────
  void _triggerStressBanner(String level, Map probs,
      {bool autoDissmiss = false}) {
    if (!mounted) return;
    setState(() {
      _stressBannerLevel = level;
      _stressBannerProbs = probs;
      _showStressBanner = true;
    });
    // _bannerAnimController.forward(from: 0);

    // ✅ Hanya auto-dismiss jika autoDissmiss = true
    if (autoDissmiss) {
      _bannerAnimController.forward(from: 0);
      Future.delayed(const Duration(seconds: 8), _dismissBanner);
    }
  }

  void _dismissBanner() {
    if (!mounted) return;
    _bannerAnimController.reverse().then((_) {
      if (mounted) setState(() => _showStressBanner = false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // ✅
    _bannerAnimController.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _screens),
          if (_showStressBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildStressBanner(),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildStressBanner() {
    final String stressVal = _stressBannerProbs['stress']?.toString() ?? '--';
    final String normalVal = _stressBannerProbs['normal']?.toString() ?? '--';
    final String happyVal = _stressBannerProbs['happy']?.toString() ?? '--';

    return SlideTransition(
      position: _bannerSlideAnim,
      child: FadeTransition(
        opacity: _bannerFadeAnim,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8B0000),
                      Color(0xFFCC2200),
                      Color(0xFFFF4422)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4422).withOpacity(0.5),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning_amber_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('⚠️ Stres Terdeteksi!',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 2),
                                Text(
                                    'AI mendeteksi tingkat stres tinggi pada Anda',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _dismissBanner,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildProbChip('😰 Stres', '$stressVal%', true),
                            _buildProbDivider(),
                            _buildProbChip('😌 Normal', '$normalVal%', false),
                            _buildProbDivider(),
                            _buildProbChip('😊 Happy', '$happyVal%', false),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _dismissBanner,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                child: const Center(
                                  child: Text('Nanti Saja',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _dismissBanner();
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text('🧘 Mulai Relaksasi',
                                      style: TextStyle(
                                          color: Color(0xFFCC2200),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProbChip(String label, String value, bool isHighlight) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: isHighlight ? Colors.yellowAccent : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
      ],
    );
  }

  Widget _buildProbDivider() =>
      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.25));

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1429),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5)),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: const Color(0xFF0F1429),
        selectedItemColor: const Color(0xFF4ECDC4),
        unselectedItemColor: Colors.white.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Stats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DASHBOARD CONTENT (Sensor + Health Data UI)
// ═══════════════════════════════════════════════════════════
class DashboardContent extends StatefulWidget {
  final StressBannerCallback? onStressDetected;
  const DashboardContent({super.key, this.onStressDetected});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent>
    with AutomaticKeepAliveClientMixin {
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
  double _currentDistance = 0.0;
  int _lastSavedHR = 0;
  final User? user = FirebaseAuth.instance.currentUser;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  double _totalCaloriesBurned = 0.0;
  double _currentCaloriesHC = 0.0;
  DateTime? _lastUpdateTime;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();

    // Reset fitur lama saat app baru start
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('latest_features');
      print('🗑️ latest_features direset');
    });

    _initApp();

    _syncTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _healthService.syncHealthData();
      _initApp();
    });

    WearOsService().sensorStream.listen((data) {
      if (!mounted) return;
      final now = DateTime.now();

      double currentHR = data['hr'] ?? 0.0;
      double ax = data['ax'] ?? 0.0;
      double ay = data['ay'] ?? 0.0;
      double az = data['az'] ?? 0.0;

      setState(() {
        _watchHeartRate = currentHR;
        _accelX = ax;
        _isWatchConnected = true;

        if (_lastUpdateTime != null) {
          double secondsElapsed =
              now.difference(_lastUpdateTime!).inMilliseconds / 1000.0;
          if (secondsElapsed > 0 && secondsElapsed < 10) {
            double calPerSec = _calculateInstantCalories(currentHR, ax, ay, az);
            _totalCaloriesBurned += calPerSec * secondsElapsed;
          }
        }
        _lastUpdateTime = now;

        _latestHealthData = HealthData(hr: currentHR, ax: ax, ay: ay, az: az);
      });

      if (now.second % 5 == 0 && currentHR > 0)
        _saveToFirebase(_latestHealthData!);
      if (now.second % 30 == 0) _persistCalories();
    });

    Future.delayed(const Duration(seconds: 1), () {
      WearOsService().initListener();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WearOsService().dispose();
    super.dispose();
  }

  void _saveToFirebase(HealthData data) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('health_logs')
          .add(data.toMap());

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'last_steps': _currentSteps,
        'last_heart_rate': _watchHeartRate,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Gagal simpan ke Firebase: $e");
    }
  }

  Future<void> _initApp() async {
    if (!mounted) return;
    print("🟡 _initApp DIJALANKAN");
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _totalCaloriesBurned = prefs.getDouble('saved_calories') ?? 0.0;

      await _handlePermissions();
      await _healthService.requestPermissions();
      final data = await _healthService.fetchTodayData();

      if (mounted) {
        setState(() {
          _currentSteps = data['steps'] ?? 0;
          _currentSleep = (data['sleep'] ?? 0.0).toDouble();
          _currentOxygen = (data['oxygen'] ?? 0.0).toDouble();
          _currentCaloriesHC = (data['calories'] ?? 0.0).toDouble();
          _currentDistance = (_currentSteps) * 0.000762;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error in _initApp: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateInstantCalories(double hr, double ax, double ay, double az) {
    if (hr < 45) return 0.0;
    double weight = 70.0;
    int age = 25;
    double caloriesPerMin =
        ((-55.0969 + (0.6309 * hr) + (0.1988 * weight) + (0.2017 * age)) /
            4.184);
    double magnitude = math.sqrt(ax * ax + ay * ay + az * az);
    double factor = magnitude > 15.0
        ? 1.5
        : magnitude > 11.0
            ? 1.2
            : 1.0;
    return (caloriesPerMin / 60) * factor;
  }

  Future<void> _persistCalories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('saved_calories', _totalCaloriesBurned);
    await prefs.setString('last_cal_update', DateTime.now().toIso8601String());
  }

  Future<void> _handlePermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.activityRecognition,
      Permission.sensors,
      Permission.notification,
    ].request();
  }

  Future<void> _loadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final String? savedData = prefs.getString('saved_notifications');
    if (savedData != null && mounted) {
      final List<dynamic> list = jsonDecode(savedData);
      setState(() {
        _notificationCount = list.where((n) => n['is_read'] == false).length;
      });
    }
  }

  // ─── Build ───────────────────────────────────────────────
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
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickStats(),
                      const SizedBox(height: 24),
                      _buildHeartRateCard(),
                      const SizedBox(height: 16),
                      _buildProgressBars(),
                      const SizedBox(height: 16),
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
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 20) return 'Good Evening';
    return 'Good Night';
  }

  Widget _buildHeader() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getGreeting(),
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 14)),
            const SizedBox(height: 4),
            StreamBuilder(
              stream: FirebaseDatabase.instance
                  .ref("users/${currentUser?.uid}")
                  .onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  final data = Map<String, dynamic>.from(
                      snapshot.data!.snapshot.value as Map);
                  return Text(data['username'] ?? "User",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold));
                }
                return const Text("User",
                    style: TextStyle(color: Colors.white));
              },
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()))
                .then((_) => _loadNotificationCount());
          },
          child: Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1F3A),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.notifications,
                    color: Colors.white54, size: 28),
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF0A0E27), width: 2),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _notificationCount > 9 ? '9+' : '$_notificationCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
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
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            value: '${_currentDistance.toStringAsFixed(2)} km',
            label: 'Distance',
            color: const Color(0xFFFF6B6B),
            bgColor: const Color(0xFFFF6B6B).withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.directions_walk,
            value: NumberFormat.decimalPattern().format(_currentSteps),
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
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }

  void _showAddWaterDialog(BuildContext context) {
    final TextEditingController waterController = TextEditingController();
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title:
            const Text('Tambah Minum', style: TextStyle(color: Colors.white)),
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
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'waterIntake': FieldValue.increment(addedLiters)});
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
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Heart Rate',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.circle,
                        color:
                            _isWatchConnected ? Colors.greenAccent : Colors.red,
                        size: 8),
                    const SizedBox(width: 4),
                    Text(_isWatchConnected ? 'Watch Live' : 'Live',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: FirebaseDatabase.instance.ref('health_metrics').onValue,
            builder: (context, snapshot) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            fontWeight: FontWeight.bold),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8, left: 4),
                        child: Text('bpm',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                            if (snapshot.hasData && snapshot.data!.exists) {
                              var data =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              waterIntake =
                                  (data['waterIntake'] ?? 0.0).toDouble();
                            }
                            return InkWell(
                              onTap: () => _showAddWaterDialog(context),
                              borderRadius: BorderRadius.circular(12),
                              child: _buildMiniStat(
                                  'Water',
                                  '${waterIntake.toStringAsFixed(1)}L',
                                  Icons.water_drop),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMiniStat(
                            'Sleep',
                            '${_currentSleep.toStringAsFixed(1)}h',
                            Icons.single_bed_sharp),
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
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8), fontSize: 11)),
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
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Today's Goals",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildProgressItem('Steps', _currentSteps, 10000, Colors.blue),
              const SizedBox(height: 16),
              _buildProgressItem(
                  'Distance', _currentDistance.toInt(), 5, Colors.orange),
              const SizedBox(height: 16),
              _buildProgressItem(
                  'Calories', _currentCaloriesHC.toInt(), 500, Colors.orange),
              const SizedBox(height: 16),
              _buildProgressItem(
                  'Sleep', (_currentSleep * 60).toInt(), 480, Colors.green,
                  displayValue: '${_currentSleep.toStringAsFixed(1)}h/8h'),
              const SizedBox(height: 16),
              _buildProgressItem(
                  'Water', (waterIntake * 1).toInt(), 2, Colors.lightBlue,
                  displayValue: '${waterIntake.toStringAsFixed(1)}L / 2L'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressItem(String label, int current, int target, Color color,
      {String suffix = '', String? displayValue}) {
    final progress = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            Text(displayValue ?? '$current / $target',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
}
