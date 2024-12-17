import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/task_service.dart';
import '../models/task_model.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<TaskModel> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.length < 3) return;

    setState(() => _isLoading = true);

    try {
      final taskService = Provider.of<TaskService>(context, listen: false);
      final result = await taskService.searchTasks(
        searchText: _searchController.text,
      );
      setState(() {
        _searchResults = result.items.cast<TaskModel>();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arama sırasında hata oluştu: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Görev ara...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: (_) => _performSearch(),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? const Center(child: Text('Sonuç bulunamadı'))
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final task = _searchResults[index];
                    return ListTile(
                      title: Text(task.title),
                      subtitle: Text(task.description),
                      trailing: Chip(
                        label: Text(
                          AppConstants.taskStatusLabels[task.status] ?? task.status,
                          style: TextStyle(
                            color: _getStatusColor(task.status),
                          ),
                        ),
                        backgroundColor: _getStatusColor(task.status).withOpacity(0.1),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/task_detail',
                          arguments: {'taskId': task.id},
                        );
                      },
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case TaskModel.statusNew:
        return Colors.blue;
      case TaskModel.statusInProgress:
        return Colors.orange;
      case TaskModel.statusCompleted:
        return Colors.green;
      case TaskModel.statusCancelled:
        return Colors.red;
      case TaskModel.statusOnHold:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}