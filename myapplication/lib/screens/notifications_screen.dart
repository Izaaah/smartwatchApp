import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/models/notification.dart' as app_models;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<app_models.Notification> _notifications = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Auto-refresh setiap 5 detik untuk membaca data baru dari background task
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadNotificationsSilent();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Refresh tanpa menampilkan loading spinner
  Future<void> _loadNotificationsSilent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Paksa baca ulang dari disk (penting untuk cross-isolate)
    final String? savedData = prefs.getString('saved_notifications');
    if (savedData != null && mounted) {
      final List<dynamic> decodedData = jsonDecode(savedData);
      final loaded = decodedData
          .map((item) => app_models.Notification.fromJson(item))
          .toList();
      // Hanya update jika ada perubahan (berdasarkan jumlah)
      if (loaded.length != _notifications.length) {
        setState(() => _notifications = loaded);
      }
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      _notifications.map((n) => n.toJson()).toList(),
    );
    await prefs.setString('saved_notifications', encodedData);
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Paksa baca fresh dari disk
    final String? savedData = prefs.getString('saved_notifications');

    if (savedData != null) {
      final List<dynamic> decodedData = jsonDecode(savedData);
      setState(() {
        _notifications = decodedData
            .map((item) => app_models.Notification.fromJson(item))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
    }
  }

  void _markAsRead(int id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
    _saveToStorage();
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    _saveToStorage();
  }

  void _deleteNotification(int id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    _saveToStorage();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifikasi dihapus')),
    );
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  // ─── Parse probabilitas dari pesan ────────────────────────────────────────
  /// Returns {normal, stress, happy} as double 0..100, or null if not found
  Map<String, double>? _parseProbabilities(String message) {
    try {
      final RegExp normalRx = RegExp(r'Normal:\s*([\d.]+)%');
      final RegExp stressRx = RegExp(r'Stres:\s*([\d.]+)%');
      final RegExp happyRx  = RegExp(r'Happy:\s*([\d.]+)%');

      final nMatch = normalRx.firstMatch(message);
      final sMatch = stressRx.firstMatch(message);
      final hMatch = happyRx.firstMatch(message);

      if (nMatch == null || sMatch == null || hMatch == null) return null;

      return {
        'normal': double.parse(nMatch.group(1)!),
        'stress': double.parse(sMatch.group(1)!),
        'happy':  double.parse(hMatch.group(1)!),
      };
    } catch (_) {
      return null;
    }
  }

  /// Pesan tanpa baris probabilitas
  String _stripProbLine(String message) {
    return message
        .replaceAll(RegExp(r'\nNormal:.*'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifikasi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount belum dibaca',
                style: const TextStyle(
                  color: Color(0xFF4ECDC4),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Tandai semua',
                style: TextStyle(color: Color(0xFF4ECDC4)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async => _loadNotifications(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(_notifications[index]);
                    },
                  ),
                ),
    );
  }

  // ─── Empty state ─────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 72, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi hasil analisis AI\nakan muncul di sini',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ─── Card ────────────────────────────────────────────────────────────────
  Widget _buildNotificationCard(app_models.Notification notification) {
    final bool isStress = notification.type == 'alert';
    final icon  = _getIcon(notification.type);
    final color = _getColor(notification.type);
    final probs = _parseProbabilities(notification.message);
    final mainMessage = _stripProbLine(notification.message);

    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(notification.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade800,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) _markAsRead(notification.id);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Stress mendapat border merah berdenyut
            border: isStress
                ? Border.all(color: Colors.red.withOpacity(0.6), width: 1.5)
                : Border.all(
                    color: notification.isRead
                        ? Colors.transparent
                        : color.withOpacity(0.25),
                    width: 1,
                  ),
            color: notification.isRead
                ? const Color(0xFF141830)
                : isStress
                    ? const Color(0xFF2A1020) // merah gelap untuk stress
                    : const Color(0xFF1A1F3A),
          ),
          child: Column(
            children: [
              // ── Header card ──────────────────────────────────────────────
              if (isStress) _buildStressBanner(),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ikon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(isStress ? 0.3 : 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    // Konten
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Judul + unread dot
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    color: isStress ? Colors.red.shade200 : Colors.white,
                                    fontSize: 15,
                                    fontWeight: notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isStress ? Colors.red : const Color(0xFF4ECDC4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Pesan (tanpa baris probs)
                          Text(
                            mainMessage,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // ── Probabilitas bars ────────────────────────────
                          if (probs != null) _buildProbabilityBars(probs),
                          const SizedBox(height: 8),
                          // Waktu
                          Text(
                            _formatTime(notification.timestamp),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Banner merah untuk Stress ───────────────────────────────────────────
  Widget _buildStressBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 14),
          const SizedBox(width: 6),
          Text(
            'PERINGATAN STRES TERDETEKSI',
            style: TextStyle(
              color: Colors.orange.shade200,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Probability progress bars ───────────────────────────────────────────
  Widget _buildProbabilityBars(Map<String, double> probs) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Probabilitas AI',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildSingleBar(
            label: 'Normal',
            value: probs['normal'] ?? 0,
            color: const Color(0xFF4ECDC4),
          ),
          const SizedBox(height: 5),
          _buildSingleBar(
            label: 'Stres',
            value: probs['stress'] ?? 0,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 5),
          _buildSingleBar(
            label: 'Happy',
            value: probs['happy'] ?? 0,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBar({
    required String label,
    required double value,
    required Color color,
  }) {
    final pct = value.clamp(0.0, 100.0);
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100.0,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 38,
          child: Text(
            '${pct.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  IconData _getIcon(String type) {
    switch (type) {
      case 'alert':       return Icons.warning_amber_rounded;
      case 'achievement': return Icons.emoji_events;
      case 'reminder':    return Icons.alarm;
      case 'health':      return Icons.favorite_outline;
      default:            return Icons.notifications_outlined;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'alert':       return Colors.red;
      case 'achievement': return Colors.amber;
      case 'reminder':    return Colors.blue;
      case 'health':      return const Color(0xFF4ECDC4);
      default:            return const Color(0xFF4ECDC4);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60)       return 'Baru saja';
    if (diff.inMinutes < 60)       return '${diff.inMinutes}m yang lalu';
    if (diff.inHours < 24)         return '${diff.inHours}j yang lalu';
    if (diff.inDays < 7)           return '${diff.inDays}h yang lalu';

    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}
