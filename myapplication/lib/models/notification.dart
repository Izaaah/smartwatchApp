class Notification {
  final int id;
  final String title;
  final String message;
  final String type; // 'health', 'reminder', 'alert', 'achievement'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data; // Additional data

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String? ?? 'health',
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'data': data,
    };
  }

  Notification copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

// Sample notifications for demo
class NotificationService {
  static List<Notification> getSampleNotifications() {
    return [
      Notification(
        id: 1,
        title: 'Heart Rate Alert',
        message: 'Your heart rate is above normal (95 BPM)',
        type: 'alert',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
        data: {'heart_rate': 95},
      ),
      Notification(
        id: 2,
        title: 'Daily Goal Achieved! 🎉',
        message:
            'Congratulations! You\'ve reached your daily step goal (10,000 steps)',
        type: 'achievement',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        data: {'steps': 10000},
      ),
      Notification(
        id: 3,
        title: 'Sleep Reminder',
        message:
            'It\'s time to prepare for bed. Aim for 8 hours of sleep tonight.',
        type: 'reminder',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      Notification(
        id: 4,
        title: 'Health Data Updated',
        message: 'Your latest health metrics have been recorded',
        type: 'health',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
      ),
      Notification(
        id: 5,
        title: 'Low Blood Oxygen',
        message: 'Your blood oxygen level is below optimal (94%)',
        type: 'alert',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: false,
        data: {'blood_oxygen': 94},
      ),
      Notification(
        id: 6,
        title: 'Weekly Report Ready',
        message: 'Your weekly health summary is available',
        type: 'health',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
  }

  static int getUnreadCount(List<Notification> notifications) {
    return notifications.where((n) => !n.isRead).length;
  }
}
class EmotionNotificationHelper {
  static Notification createFromPrediction({
    required int id,
    required String label, // 'Baseline', 'Stress', 'Amusement'
    required double confidence,
    Map<String, dynamic>? sensorMetrics,
  }) {
    String title;
    String message;
    String type;

    switch (label) {
      case 'Stress':
        title = 'Alert: High Stress Level';
        message = 'Model kami mendeteksi tingkat stres yang tinggi. Tarik napas dalam sejenak.';
        type = 'alert';
        break;
      case 'Amusement':
        title = 'Daily Goal: Mood Positive 🎉';
        message = 'Anda terlihat sangat ceria! Pertahankan kondisi positif ini.';
        type = 'achievement';
        break;
      default: // Baseline
        title = 'Health Status: Stable';
        message = 'Kondisi fisiologis Anda terpantau normal dan stabil.';
        type = 'health';
    }

    return Notification(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      data: {
        'prediction': label,
        'confidence': confidence,
        ...?sensorMetrics,
      },
    );
  }
}