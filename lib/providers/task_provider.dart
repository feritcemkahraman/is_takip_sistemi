import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _taskService;
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;

  TaskProvider(this._taskService);

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTasks({
    String? status,
    String? assignedTo,
    String? department,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    int? priority,
    bool? isArchived,
    String? orderBy,
    bool descending = true,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _taskService.searchTasks(
        status: status,
        assignedTo: assignedTo,
        department: department,
        startDate: startDate,
        endDate: endDate,
        tags: tags,
        priority: priority,
        isArchived: isArchived,
        orderBy: orderBy,
        descending: descending,
        page: page,
        pageSize: pageSize,
      );

      _tasks = result;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TaskModel?> getTask(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final task = await _taskService.getTask(id);
      _isLoading = false;
      notifyListeners();
      return task;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> createTask(TaskModel task) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _taskService.createTask(task);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _taskService.updateTask(task);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _taskService.deleteTask(id);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _taskService.updateStatus(id, status);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePriority(String id, int priority) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _taskService.updatePriority(id, priority);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addComment(String taskId, String comment, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _taskService.addComment(taskId, comment, userId);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAttachment(String taskId, String attachmentUrl) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _taskService.addAttachment(taskId, attachmentUrl);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeAttachment(String taskId, String attachmentUrl) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _taskService.removeAttachment(taskId, attachmentUrl);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTag(String taskId, String tag) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _taskService.addTag(taskId, tag);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeTag(String taskId, String tag) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _taskService.removeTag(taskId, tag);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> archiveTask(String taskId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _taskService.archiveTask(taskId);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> unarchiveTask(String taskId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _taskService.unarchiveTask(taskId);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
