import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentService {
  final CollectionReference _departmentsRef =
      FirebaseFirestore.instance.collection('departments');

  Future<List<String>> getAllDepartments() async {
    try {
      final snapshot = await _departmentsRef.get();
      return snapshot.docs.map((doc) => doc.get('name') as String).toList();
    } catch (e) {
      throw Exception('Departmanlar yüklenirken hata: $e');
    }
  }

  Future<void> addDepartment(String name) async {
    try {
      await _departmentsRef.add({
        'name': name,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Departman eklenirken hata: $e');
    }
  }

  Future<void> updateDepartment(String id, String name) async {
    try {
      await _departmentsRef.doc(id).update({
        'name': name,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Departman güncellenirken hata: $e');
    }
  }

  Future<void> deleteDepartment(String id) async {
    try {
      await _departmentsRef.doc(id).delete();
    } catch (e) {
      print('Departman silinirken hata: $e');
      throw Exception('Departman silinemedi');
    }
  }

  Stream<List<String>> getDepartmentsStream() {
    return _departmentsRef
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.get('name') as String).toList())
        .handleError((e) {
          print('Departman akışı hatası: $e');
          return [];
        });
  }

  Future<bool> departmentExists(String name) async {
    try {
      final snapshot = await _departmentsRef
          .where('name', isEqualTo: name)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Departman kontrolü yapılırken hata: $e');
      return false;
    }
  }

  Future<String?> getDepartmentId(String name) async {
    try {
      final snapshot = await _departmentsRef
          .where('name', isEqualTo: name)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.id;
    } catch (e) {
      print('Departman ID\'si alınırken hata: $e');
      return null;
    }
  }

  Future<List<String>> searchDepartments(String searchText) async {
    try {
      final snapshot = await _departmentsRef
          .where('name', isGreaterThanOrEqualTo: searchText)
          .where('name', isLessThan: searchText + '\uf8ff')
          .get();

      return snapshot.docs.map((doc) => doc.get('name') as String).toList();
    } catch (e) {
      print('Departman arama hatası: $e');
      rethrow;
    }
  }
} 