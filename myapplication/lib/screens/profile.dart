import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/edit_profile.dart';
import 'package:frontend/screens/goals_targets_screen.dart';
import 'package:frontend/screens/units_screen.dart';
import 'package:frontend/screens/about_screen.dart';
import 'package:frontend/screens/privacy_policy_screen.dart';
import 'package:frontend/screens/terms_of_service_screen.dart';
// import 'package:frontend/models/user.dart';
import 'package:frontend/services/auth_service.dart'; 
import 'package:frontend/screens/login_screen.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _heartRateMonitoring = true;
  bool _sleepTracking = true;
  bool _activityReminders = false;
  double _selectedWaterGoal = 2.0;
  // User? _user;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // _loadProfile();
  }

  // Future<void> _loadProfile() async {
  //   await Future.delayed(const Duration(milliseconds: 500));
    
  //   if (mounted) {
  //     setState(() {
  //       _user = User(
  //         id: 1,
  //         username: 'johndoe',
  //         email: "john.doe@example.com",
  //         name: "John Doe",
  //         age: 25,
  //         gender: "male",
  //         height: 48.0,
  //         weight: 165.0,
  //       );
  //     });
  //   }
    
  // }
  

  // Tambahkan parameter userData agar bisa menerima Map dari Firestore
Future<void> _navigateToEditProfile(Map<String, dynamic> userData) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      // Kita kirim userData langsung
      builder: (context) => EditProfileScreen(user: userData),
    ),
  );

  // if (newUser != null) {
  //     setState(() {
  //       _user = newUser;
  //     });
  //   }
  // Tidak perlu setState karena StreamBuilder akan update otomatis saat data di Firebase berubah
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFF0A0E27),
      backgroundColor: const Color(0xFF0F1221),
      body: StreamBuilder<DocumentSnapshot>(
        // Ambil data real-time dari Firestore berdasarkan UID
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Data tidak ditemukan", style: TextStyle(color: Colors.white)));
          }

          // Ambil data dari Firestore
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String displayName = userData['username'] ?? "User";
          String displayEmail = userData['email'] ?? currentUser?.email ?? "";
          // _buildProfileHeader(username, email),
      
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(displayName, displayEmail),
              const SizedBox(height: 24),
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildSettingsSection(context, userData),
              const SizedBox(height: 24),
              _buildLogoutButton(context), // Panggil fungsi ini di sini
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
        },
    ),
    );
  }

  Widget _buildProfileHeader(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_circle,
                  size: 55,
                  color: Colors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  // _user?.email ?? 
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _buildInfoBadgeCompact('Level 5'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadgeCompact(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Color(0xFFFFD700), size: 14),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildInfoBadge(String title, IconData icon, String subtitle) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
  //     decoration: BoxDecoration(
  //       color: Colors.white.withOpacity(0.2),
  //       borderRadius: BorderRadius.circular(18),
  //       border: Border.all(
  //         color: Colors.white.withOpacity(0.4),
  //         width: 1.5,
  //       ),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(6),
  //           decoration: BoxDecoration(
  //             color: const Color(0xFFFFD700).withOpacity(0.3),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Icon(icon, color: const Color(0xFFFFD700), size: 18),
  //         ),
  //         const SizedBox(width: 12),
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               title,
  //               style: const TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 15,
  //                 fontWeight: FontWeight.w700,
  //               ),
  //             ),
  //             Text(
  //               subtitle,
  //               style: TextStyle(
  //                 color: Colors.white.withOpacity(0.85),
  //                 fontSize: 11,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Steps',
              '1,234,567',
              Icons.directions_walk,
              const Color(0xFF4ECDC4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Workouts',
              '124',
              Icons.fitness_center,
              const Color(0xFFFF6B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, Map<String, dynamic> userData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSettingsTile(
            'Personal Information',
            'Update your profile details',
            Icons.person_outline,
            const Color(0xFF4ECDC4),
            onTap: () => _navigateToEditProfile(userData),
          ), 
          const SizedBox(height: 12),
          _buildSettingsTile(
            'Goals & Targets',
            'Set your daily goals',
            Icons.flag_outlined,
            const Color(0xFFFF6B6B),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoalsTargetsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            'Units',
            'Metric or Imperial',
            Icons.straighten_outlined,
            const Color(0xFF9B59B6),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UnitsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSwitchTile(
            'Enable Notifications',
            'Receive activity alerts',
            Icons.notifications_outlined,
            _notificationsEnabled,
            (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            'Heart Rate Monitoring',
            'Continuous tracking',
            Icons.favorite_outline,
            _heartRateMonitoring,
            (value) {
              setState(() {
                _heartRateMonitoring = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            'Sleep Tracking',
            'Track your sleep patterns',
            Icons.bedtime_outlined,
            _sleepTracking,
            (value) {
              setState(() {
                _sleepTracking = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            'Activity Reminders',
            'Get moving reminders',
            Icons.access_time_outlined,
            _activityReminders,
            (value) {
              setState(() {
                _activityReminders = value;
              });
            },
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Daily Goals',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSliderTile(
            'Water Intake',
            '${_selectedWaterGoal.toStringAsFixed(1)}L per day',
            Icons.water_drop_outlined,
            _selectedWaterGoal,
            0.5,
            5.0,
            (value) {
              setState(() {
                _selectedWaterGoal = value;
              });
            },
          ),
          const SizedBox(height: 24),
          _buildSettingsTile(
            'About',
            'App version 1.0.0',
            Icons.info_outline,
            Colors.grey,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            'Privacy Policy',
            'Read our privacy policy',
            Icons.privacy_tip_outlined,
            Colors.grey,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            'Terms of Service',
            'Read terms and conditions',
            Icons.description_outlined,
            Colors.grey,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

//   @override
// Widget build(BuildContext context) {
//   return Column(
//     children: [
//       _buildSettingsSection(context), // Masukkan context di sini
//     ],
//   );
// }

  Widget _buildSettingsTile(
      String title, String subtitle, IconData icon, Color color,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
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
              color: const Color(0xFF4ECDC4).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF4ECDC4), size: 24),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4ECDC4),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String value,
    IconData icon,
    double currentValue,
    double min,
    double max,
    ValueChanged<double> onChanged,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3498DB).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF3498DB), size: 24),
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
                      value,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: currentValue,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: const Color(0xFF3498DB),
            inactiveColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: ElevatedButton(
      onPressed: () async {
        // Tampilkan dialog konfirmasi
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F3A),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            content: const Text('Are you sure you want to logout?', 
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () async {
                  // 1. Logout dari Firebase Auth
                  await FirebaseAuth.instance.signOut(); //
                  
                  // 2. Hapus token di SharedPreferences melalui AuthService
                  await AuthService.logout(); //
                  
                  if (!context.mounted) return;
                  
                  // 3. Kembali ke halaman Login dan hapus semua history route
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.withOpacity(0.1),
        foregroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withOpacity(0.3)),
        ),
        elevation: 0,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout),
          SizedBox(width: 8),
          Text(
            'Logout Account',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDangerousTile(String title, String subtitle, IconData icon,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.red,
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
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
