import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardService {
  final FirebaseFirestore _firestore;

  DashboardService({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<Map<String, dynamic>> getDashboardData({
    required String userId,
    required bool isAdmin,
  }) async {
    try {
      print('DashboardService: Görev verileri alınıyor...');
      
      // Görev sorgusu
      Query<Map<String, dynamic>> tasksQuery = _firestore.collection('tasks');
      
      // Admin değilse sadece kendi görevlerini görsün
      if (!isAdmin) {
        tasksQuery = tasksQuery.where('assignedTo', isEqualTo: userId);
      }

      final tasksSnapshot = await tasksQuery.get();
      
      // Görev sayıları
      int activeTasksCount = 0;
      int pendingTasksCount = 0;
      int completedTasksCount = 0;

      for (var doc in tasksSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'pending';
        switch (status) {
          case 'active':
            activeTasksCount++;
            break;
          case 'pending':
            pendingTasksCount++;
            break;
          case 'completed':
            completedTasksCount++;
            break;
        }
      }

      print('DashboardService: Görev sayıları - Aktif: $activeTasksCount, Bekleyen: $pendingTasksCount, Tamamlanan: $completedTasksCount');

      // Kullanıcı sayısı (sadece admin için)
      int userCount = 0;
      if (isAdmin) {
        print('DashboardService: Kullanıcı sayısı alınıyor...');
        final usersSnapshot = await _firestore.collection('users').count().get();
        userCount = usersSnapshot.count ?? 0;
        print('DashboardService: Toplam kullanıcı sayısı: $userCount');
      }

      // Okunmamış bildirim sayısı
      print('DashboardService: Okunmamış bildirimler alınıyor...');
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      
      final unreadCount = notificationsSnapshot.count ?? 0;
      print('DashboardService: Okunmamış bildirim sayısı: $unreadCount');

      // Son görevler
      print('DashboardService: Son görevler alınıyor...');
      final recentTasksSnapshot = await tasksQuery
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final recentTasks = recentTasksSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] as String? ?? '',
          'description': data['description'] as String? ?? '',
          'status': data['status'] as String? ?? 'pending',
          'createdAt': data['createdAt'] as Timestamp? ?? Timestamp.now(),
        };
      }).toList();

      print('DashboardService: ${recentTasks.length} son görev bulundu');

      final result = {
        'activeTasks': activeTasksCount,
        'pendingTasks': pendingTasksCount,
        'completedTasks': completedTasksCount,
        'userCount': userCount,
        'unreadNotifications': unreadCount,
        'recentTasks': recentTasks,
      };

      print('DashboardService: Tüm veriler başarıyla alındı: $result');
      return result;
    } catch (e) {
      print('DashboardService Hatası: $e');
      throw Exception('Dashboard verileri alınırken hata oluştu: $e');
    }
  }
} 