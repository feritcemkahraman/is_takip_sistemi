import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/search_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

class SearchService {
  final FirebaseFirestore _firestore;

  SearchService({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<List<TaskModel>> searchTasks(SearchFilter filter) async {
    try {
      Query query = _firestore.collection('tasks');

      // Metin araması
      if (filter.searchText != null && filter.searchText!.isNotEmpty) {
        query = query.where('title', isGreaterThanOrEqualTo: filter.searchText)
            .where('title', isLessThan: '${filter.searchText}\uf8ff');
      }

      // Departman filtresi
      if (filter.hasDepartmentFilter()) {
        query = query.where('department', whereIn: filter.departments);
      }

      // Durum filtresi
      if (filter.hasStatusFilter()) {
        query = query.where('status', whereIn: filter.statuses);
      }

      // Öncelik filtresi
      if (filter.hasPriorityFilter()) {
        query = query.where('priority', whereIn: filter.priorities);
      }

      // Tarih filtresi
      if (filter.startDate != null) {
        query = query.where('dueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!));
      }
      if (filter.endDate != null) {
        query = query.where('dueDate',
            isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!));
      }

      final snapshot = await query.limit(50).get();
      return snapshot.docs
          .map((doc) => TaskModel.fromMap({...(doc.data() as Map<String, dynamic>), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Görev arama hatası: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> searchUsers(SearchFilter filter) async {
    try {
      Query query = _firestore.collection('users');

      // Metin araması
      if (filter.searchText != null && filter.searchText!.isNotEmpty) {
        query = query.where('name', isGreaterThanOrEqualTo: filter.searchText)
            .where('name', isLessThan: '${filter.searchText}\uf8ff');
      }

      // Departman filtresi
      if (filter.hasDepartmentFilter()) {
        query = query.where('department', whereIn: filter.departments);
      }

      // Rol filtresi
      if (filter.hasRoleFilter()) {
        query = query.where('role', whereIn: filter.roles);
      }

      final snapshot = await query.limit(50).get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap({...(doc.data() as Map<String, dynamic>), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Kullanıcı arama hatası: $e');
      rethrow;
    }
  }

  List<String> _generateKeywords(String text) {
    final words = text.toLowerCase().split(' ');
    final keywords = <String>{};

    for (final word in words) {
      for (int i = 1; i <= word.length; i++) {
        keywords.add(word.substring(0, i));
      }
    }

    return keywords.toList();
  }
}