import '../models/notification.dart' as app_models; // Sesuaikan dengan path model Anda

class EmotionNotificationHandler {
  // Fungsi untuk mengubah hasil prediksi menjadi objek Notification
  static app_models.Notification createNotificationFromAI(
    String label, {Map<String, String>? probs}){
    final int id = DateTime.now().millisecondsSinceEpoch;
    
    String probText = '';
    if (probs != null) {
      probText = '\nNormal: ${probs['normal']}% | Stres: ${probs['stress']}% | Happy: ${probs['happy']}%';
    }

    if (label == 'Stress') {
      return app_models.Notification(
        id: id,
        title: '⚠️ Peringatan Stres Terdeteksi!',
        message: 'Detak jantung dan aktivitas Anda menunjukkan indikasi stres. Yuk, istirahat sejenak.$probText',
        type: 'alert',
        timestamp: DateTime.now(),
        isRead: false,
        data: {'source': 'WESAD_AI_Model'},
      );
    } else if (label == 'Happy' || label == 'Amusement') {
      return app_models.Notification(
        id: id,
        title: 'Mood Anda Sangat Baik! 🎉',
        message: 'Terus pertahankan energi positif ini untuk produktivitas Anda hari ini.$probText',
        type: 'achievement',
        timestamp: DateTime.now(),
        isRead: false,
      );
    } else {
      return app_models.Notification(
        id: id,
        title: 'Kondisi Tubuh Stabil',
        message: 'Status kesehatan Anda saat ini terpantau normal.$probText',
        type: 'health',
        timestamp: DateTime.now(),
        isRead: false,
      );
    }
  }
}