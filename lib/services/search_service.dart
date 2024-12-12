import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/search_model.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Görevleri ara
  Future<SearchResult<TaskModel>> searchTasks(
    SearchFilter filter, {
    int limit = 20,
    String? nextPageToken,
  }) async {
    Query query = _firestore.collection('tasks');

    // Metin araması
    if (filter.searchText != null && filter.searchText!.isNotEmpty) {
      query = query.where('keywords', arrayContains: filter.searchText!.toLowerCase());
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
    if (filter.hasDateFilter()) {
      if (filter.startDate != null) {
        query = query.where('dueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!));
      }
      if (filter.endDate != null) {
        query = query.where('dueDate',
            isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!));
      }
    }

    // Atanan kişi filtresi
    if (filter.assignedTo != null) {
      query = query.where('assignedTo', isEqualTo: filter.assignedTo);
    }

    // Oluşturan kişi filtresi
    if (filter.createdBy != null) {
      query = query.where('createdBy', isEqualTo: filter.createdBy);
    }

    // Tamamlanma durumu filtresi
    if (filter.isCompleted != null) {
      query = query.where('isCompleted', isEqualTo: filter.isCompleted);
    }

    // Etiket filtresi
    if (filter.hasTagFilter()) {
      query = query.where('tags', arrayContainsAny: filter.tags!);
    }

    // Sıralama
    if (filter.sortBy != null) {
      query = query.orderBy(
        filter.sortBy!,
        descending: !(filter.sortAscending ?? true),
      );
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    // Sayfalama
    if (nextPageToken != null) {
      final lastDoc = await _firestore.doc(nextPageToken).get();
      query = query.startAfterDocument(lastDoc);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    final tasks = snapshot.docs
        .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    return SearchResult(
      items: tasks,
      totalCount: snapshot.docs.length,
      hasMore: snapshot.docs.length == limit,
      nextPageToken:
          snapshot.docs.isNotEmpty ? snapshot.docs.last.reference.path : null,
      appliedFilter: filter,
    );
  }

  // Toplantıları ara
  Future<SearchResult<MeetingModel>> searchMeetings(
    SearchFilter filter, {
    int limit = 20,
    String? nextPageToken,
  }) async {
    Query query = _firestore.collection('meetings');

    // Metin araması
    if (filter.searchText != null && filter.searchText!.isNotEmpty) {
      query = query.where('keywords', arrayContains: filter.searchText!.toLowerCase());
    }

    // Departman filtresi
    if (filter.hasDepartmentFilter()) {
      query = query.where('departments', arrayContainsAny: filter.departments!);
    }

    // Durum filtresi
    if (filter.hasStatusFilter()) {
      query = query.where('status', whereIn: filter.statuses);
    }

    // Tarih filtresi
    if (filter.hasDateFilter()) {
      if (filter.startDate != null) {
        query = query.where('startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!));
      }
      if (filter.endDate != null) {
        query = query.where('endTime',
            isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!));
      }
    }

    // Organizatör filtresi
    if (filter.createdBy != null) {
      query = query.where('organizerId', isEqualTo: filter.createdBy);
    }

    // Katılımcı filtresi
    if (filter.assignedTo != null) {
      query = query.where('participantIds', arrayContains: filter.assignedTo);
    }

    // Sıralama
    if (filter.sortBy != null) {
      query = query.orderBy(
        filter.sortBy!,
        descending: !(filter.sortAscending ?? true),
      );
    } else {
      query = query.orderBy('startTime', descending: true);
    }

    // Sayfalama
    if (nextPageToken != null) {
      final lastDoc = await _firestore.doc(nextPageToken).get();
      query = query.startAfterDocument(lastDoc);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    final meetings = snapshot.docs
        .map((doc) => MeetingModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    return SearchResult(
      items: meetings,
      totalCount: snapshot.docs.length,
      hasMore: snapshot.docs.length == limit,
      nextPageToken:
          snapshot.docs.isNotEmpty ? snapshot.docs.last.reference.path : null,
      appliedFilter: filter,
    );
  }

  // Kullanıcıları ara
  Future<SearchResult<UserModel>> searchUsers(
    SearchFilter filter, {
    int limit = 20,
    String? nextPageToken,
  }) async {
    Query query = _firestore.collection('users');

    // Metin araması
    if (filter.searchText != null && filter.searchText!.isNotEmpty) {
      final searchText = filter.searchText!.toLowerCase();
      query = query.where('keywords', arrayContains: searchText);
    }

    // Departman filtresi
    if (filter.hasDepartmentFilter()) {
      query = query.where('department', whereIn: filter.departments);
    }

    // Rol filtresi
    if (filter.type != null) {
      query = query.where('role', isEqualTo: filter.type);
    }

    // Aktiflik durumu filtresi
    if (filter.isCompleted != null) {
      query = query.where('isActive', isEqualTo: filter.isCompleted);
    }

    // Sıralama
    if (filter.sortBy != null) {
      query = query.orderBy(
        filter.sortBy!,
        descending: !(filter.sortAscending ?? true),
      );
    } else {
      query = query.orderBy('name');
    }

    // Sayfalama
    if (nextPageToken != null) {
      final lastDoc = await _firestore.doc(nextPageToken).get();
      query = query.startAfterDocument(lastDoc);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    final users = snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    return SearchResult(
      items: users,
      totalCount: snapshot.docs.length,
      hasMore: snapshot.docs.length == limit,
      nextPageToken:
          snapshot.docs.isNotEmpty ? snapshot.docs.last.reference.path : null,
      appliedFilter: filter,
    );
  }

  // Arama geçmişini kaydet
  Future<void> saveSearchHistory(String userId, String searchText) async {
    final searchHistory = _firestore
        .collection('users')
        .doc(userId)
        .collection('search_history');

    // Aynı aramayı kontrol et
    final existing = await searchHistory
        .where('text', isEqualTo: searchText)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Varolan aramayı güncelle
      await existing.docs.first.reference.update({
        'lastUsed': FieldValue.serverTimestamp(),
        'useCount': FieldValue.increment(1),
      });
    } else {
      // Yeni arama ekle
      await searchHistory.add({
        'text': searchText,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsed': FieldValue.serverTimestamp(),
        'useCount': 1,
      });

      // Maksimum 10 arama geçmişi tut
      final allSearches = await searchHistory
          .orderBy('lastUsed', descending: true)
          .get();

      if (allSearches.docs.length > 10) {
        for (var i = 10; i < allSearches.docs.length; i++) {
          await allSearches.docs[i].reference.delete();
        }
      }
    }
  }

  // Arama geçmişini getir
  Stream<List<String>> getSearchHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('search_history')
        .orderBy('lastUsed', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()['text'] as String).toList());
  }

  // Arama geçmişini temizle
  Future<void> clearSearchHistory(String userId) async {
    final searchHistory = await _firestore
        .collection('users')
        .doc(userId)
        .collection('search_history')
        .get();

    for (var doc in searchHistory.docs) {
      await doc.reference.delete();
    }
  }
} 