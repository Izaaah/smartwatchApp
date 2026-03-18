import '../models/notification.dart'; // Sesuaikan dengan path model Anda

class EmotionNotificationHandler {
  // Fungsi untuk mengubah hasil prediksi menjadi objek Notification
  static Notification createNotificationFromAI(String label) {
    final int id = DateTime.now().millisecondsSinceEpoch;
    
    if (label == 'Stress') {
      return Notification(
        id: id,
        title: 'Peringatan Stres Terdeteksi!',
        message: 'Detak jantung dan aktivitas Anda menunjukkan indikasi stres. Yuk, istirahat sejenak.',
        type: 'alert',
        timestamp: DateTime.now(),
        isRead: false,
        data: {'source': 'WESAD_AI_Model'},
      );
    } else if (label == 'Amusement') {
      return Notification(
        id: id,
        title: 'Mood Anda Sangat Baik! 🎉',
        message: 'Terus pertahankan energi positif ini untuk produktivitas Anda hari ini.',
        type: 'achievement',
        timestamp: DateTime.now(),
        isRead: false,
      );
    } else {
      return Notification(
        id: id,
        title: 'Kondisi Tubuh Stabil',
        message: 'Status kesehatan Anda saat ini terpantau normal.',
        type: 'health',
        timestamp: DateTime.now(),
        isRead: false,
      );
    }
  }
}