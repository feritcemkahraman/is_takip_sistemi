import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../constants/app_constants.dart';

class ProjectService {
  final FirebaseFirestore _firestore;
  final String _collection = AppConstants.projectsCollection;

  ProjectService({FirebaseFirestore? firestore}) 
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _projectsRef => 
    _firestore.collection(_collection);

  // Proje oluşturma
  Future<ProjectModel> createProject(ProjectModel project) async {
    try {
      final docRef = await _projectsRef.add(project.toMap());
      final createdProject = project.copyWith(id: docRef.id);
      return createdProject;
    } catch (e) {
      throw Exception('Proje oluşturulurken hata oluştu: $e');
    }
  }

  // Proje güncelleme
  Future<void> updateProject(ProjectModel project) async {
    try {
      await _projectsRef.doc(project.id).update(project.toMap());
    } catch (e) {
      throw Exception('Proje güncellenirken hata oluştu: $e');
    }
  }

  // Proje silme
  Future<void> deleteProject(String projectId) async {
    try {
      await _projectsRef.doc(projectId).delete();
    } catch (e) {
      throw Exception('Proje silinirken hata oluştu: $e');
    }
  }

  // Tek proje getirme
  Future<ProjectModel?> getProject(String projectId) async {
    try {
      final doc = await _projectsRef.doc(projectId).get();
      if (!doc.exists) return null;
      return ProjectModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Proje getirilirken hata oluştu: $e');
    }
  }

  // Tüm projeleri getirme
  Stream<List<ProjectModel>> getAllProjects() {
    return _projectsRef
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => ProjectModel.fromMap(doc.data()))
        .toList());
  }

  // Kullanıcının projelerini getirme
  Stream<List<ProjectModel>> getUserProjects(String userId) {
    return _projectsRef
      .where('teamMembers', arrayContains: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => ProjectModel.fromMap(doc.data()))
        .toList());
  }

  // Proje istatistiklerini getirme
  Future<Map<String, dynamic>> getProjectStats() async {
    try {
      final QuerySnapshot allProjects = await _projectsRef.get();
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);

      int totalProjects = allProjects.docs.length;
      int activeProjects = 0;
      int completedProjects = 0;
      Map<String, int> monthlyProjects = {};

      for (var doc in allProjects.docs) {
        final project = ProjectModel.fromMap(doc.data() as Map<String, dynamic>);
        
        if (project.status == 'active') activeProjects++;
        if (project.status == 'completed') completedProjects++;

        if (project.createdAt.isAfter(sixMonthsAgo)) {
          String monthKey = '${project.createdAt.year}-${project.createdAt.month}';
          monthlyProjects[monthKey] = (monthlyProjects[monthKey] ?? 0) + 1;
        }
      }

      return {
        'totalProjects': totalProjects,
        'activeProjects': activeProjects,
        'completedProjects': completedProjects,
        'monthlyProjects': monthlyProjects,
      };
    } catch (e) {
      throw Exception('Proje istatistikleri getirilirken hata oluştu: $e');
    }
  }
}
