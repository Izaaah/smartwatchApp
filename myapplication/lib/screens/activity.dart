import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildTodaySummary(),
              const SizedBox(height: 24),
              _buildActivityTypes(context),
              const SizedBox(height: 24),
              _buildTodayActivities(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stats',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.access_time,
            color: Colors.white54,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4ECDC4),
            const Color(0xFF26D0CE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '8,234',
                  'Steps',
                  Icons.directions_walk,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  '2.4 km',
                  'Distance',
                  Icons.straighten,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  '234',
                  'Calories',
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Widget _buildActivityTypes() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Stress Relief Activities',
  //         style: TextStyle(
  //           color: Colors.white,
  //           fontSize: 18,
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //       const SizedBox(height: 16),
  //       Row(
  //         children: [
  //           Expanded(
  //             child: _buildActivityTypeCard(
  //               'Breathing',
  //               'Deep & Slow',
  //               Icons.air,
  //               const Color(0xFF4ECDC4),
  //               () {
  //                 print('Start Breathing');
  //               } ,
  //             ),
  //           ),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: _buildActivityTypeCard(
  //               'Meditation',
  //               'Calm Mind',
  //               Icons.directions_bike,
  //               const Color(0xFF9B59B6),
  //               () => print('Start Meditation'),
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 12),
  //       Row(
  //         children: [
  //           Expanded(
  //             child: _buildActivityTypeCard(
  //               'Stress Scan',
  //               'AI Diagnosis',
  //               Icons.directions_walk,
  //               const Color(0xFF3498DB),
  //               () => print('Start Scan'),
  //             ),
  //           ),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: _buildActivityTypeCard(
  //               'Focus Mode',
  //               'Productivity',
  //               Icons.fitness_center,
  //               const Color(0xFFFF6B6B),
  //               () => print('Start Focus'),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

Widget _buildActivityTypes(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Stress Relief Activities',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          // Kartu 1
          _buildActivityTypeCard(
            'Breathing',            // 1. Title
            'Deep & Slow',          // 2. Subtitle
            Icons.air,              // 3. Icon
            const Color(0xFF4ECDC4),// 4. Color
            () {                    // 5. onTap (Fungsi Klik)
              print('Breathing Clicked');
            },
          ),
          // Kartu 2
          _buildActivityTypeCard(
            'Meditation',
            'Calm Mind',
            Icons.self_improvement,
            const Color(0xFFFFD93D),
            () {
              _showMeditationDialog(context);
            },
          ),
          // Kartu 3
          _buildActivityTypeCard(
            'Stress Scan',
            'AI Diagnosis',
            Icons.psychology,
            const Color(0xFFFF6B6B),
            () {
              print('Focus Clicked');
            },
          ),
          // Kartu 4
          _buildActivityTypeCard(
            'Focus Mode',
            'Productivity',
            Icons.timer,
            const Color(0xFF6C5CE7),
            () => _startRecording(context, 'Focus'),
          ),
        ],
      ),
    ],
  );
}
  Widget _buildActivityTypeCard(
    String title,
    String subtitle,
    // String duration,
    IconData icon,
    Color color,
    VoidCallback onTap,
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
      // child: Column(
      //   children: [
      //     Container(
      //       padding: const EdgeInsets.all(10),
      //       decoration: BoxDecoration(
      //         color: color.withOpacity(0.15),
      //         borderRadius: BorderRadius.circular(12),
      //       ),
      //       child: Icon(icon, color: color, size: 24),
      //     ),
      //     const SizedBox(height: 12),
      //     Text(
      //       title,
      //       style: const TextStyle(
      //         color: Colors.white,
      //         fontSize: 14,
      //         fontWeight: FontWeight.w600,
      //       ),
      //     ),
      //     const SizedBox(height: 4),
      //     Text(
      //       duration,
      //       style: TextStyle(
      //         color: Colors.white.withOpacity(0.6),
      //         fontSize: 12,
      //       ),
      //     ),
      //   ],
      // ),
      child: Material( // Tambahkan Material agar efek Ripple (cipratan) terlihat
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, // Fungsi klik dimasukkan di sini
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

// Ubah fungsi ini di activity.dart
void _startRecording(BuildContext context, String type) {
  if (type == 'Focus') {
    _showPomodoroDialog(context); // Kirim context ke fungsi dialog
  } else if (type == 'Meditation'){
    _showMeditationDialog(context);
  } else {
    print("Memulai sesi: $type");
  }
}

void _showPomodoroDialog(BuildContext context) {
  int totalSeconds = 1500; // 25 Menit
  Timer? timer;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          
          void startTimer() {
            if (timer != null) return;
            timer = Timer.periodic(const Duration(seconds: 1), (t) {
              if (totalSeconds > 0) {
                setState(() => totalSeconds--);
              } else {
                t.cancel();
              }
            });
          }

          String formatTime(int s) {
            return "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1F3A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text("Pomodoro Focus", style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatTime(totalSeconds),
                  style: const TextStyle(color: Color(0xFF6C5CE7), fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text("Stay focused to lower your stress.", 
                    style: TextStyle(color: Colors.white60), textAlign: TextAlign.center),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.pop(context);
                },
                child: const Text("Stop", style: TextStyle(color: Colors.redAccent)),
              ),
              if (timer == null)
                ElevatedButton(
                  onPressed: startTimer,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                  child: const Text("Start Now"),
                ),
            ],
          );
        },
      );
    },
  );
}

void _showMeditationDialog(BuildContext context){
  int elapsedSeconds = 0;
  Timer? timer;
  int? _hrBefore = await getHRFromLocal(hashCode);
  int? _hrAfter;
  final player = AudioPlayer();

  // _hrBefore = _watchHeartRate;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState){

          void startMeditation() async {
            if (timer != null) return;

            try {
              await player.play(AssetSource('audio/meditation.mp3'));
              player.setReleaseMode(ReleaseMode.loop);
            } catch (e) {
              print ("Error playing audio: $e");
            }

            timer = Timer.periodic(const Duration(seconds: 1), (t) {
              setState(() => elapsedSeconds++);
            });
          }

          void endMeditation() async {
            int currentHR = await fetchCurrentHR();
            await saveHRToLocal(currentHR);

            setState(() {
              _hrAfter = currentHR;
            });
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1F3A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text("Meditation Session", style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.spa, color: Color(0xFFFFD93D), size: 64),
                const SizedBox(height: 16),
                Text(
                  "${(elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(elapsedSeconds % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.white, fontSize: 54, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: (){
                  timer?.cancel();
                  player.stop();
                  player.dispose();
                  Navigator.pop(context);
                }, 
                child: const Text("End Session", style: TextStyle(color: Colors.redAccent)),
              ),
              if (timer == null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD93D)),
                  onPressed: startMeditation,
                  child: const Text("Start Now", style: TextStyle(color: Colors.black87)),
                  ),
            ],
          );
        },
      );
      },
      );
    }
// }
  
  Future<void> saveHRToLocal(int hrValue) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_hr', hrValue);
  }

  Future<int> getHRFromLocal() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_hr') ?? 0;
  }

  // Future<int> fetchCurrentHR() async {
  //   try {
  //     final snapshot = await Fire
  //   }
  // }
  Widget _buildTodayActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activities Today',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActivityItem(
          'Morning Run',
          '09:00 AM',
          '6.2 km • 45 min',
          Icons.directions_run,
          const Color(0xFF4ECDC4),
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          'Cycling Session',
          '11:30 AM',
          '12.8 km • 30 min',
          Icons.directions_bike,
          const Color(0xFF9B59B6),
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          'Lunch Walk',
          '01:00 PM',
          '2.5 km • 35 min',
          Icons.directions_walk,
          const Color(0xFF3498DB),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    String details,
    IconData icon,
    Color color,
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
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            details,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
