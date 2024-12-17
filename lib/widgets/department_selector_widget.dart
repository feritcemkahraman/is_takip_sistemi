import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/department_service.dart';

class DepartmentSelectorWidget extends StatefulWidget {
  final Function(String) onDepartmentSelected;
  final String? selectedDepartment;

  const DepartmentSelectorWidget({
    Key? key,
    required this.onDepartmentSelected,
    this.selectedDepartment,
  }) : super(key: key);

  @override
  _DepartmentSelectorWidgetState createState() => _DepartmentSelectorWidgetState();
}

class _DepartmentSelectorWidgetState extends State<DepartmentSelectorWidget> {
  final DepartmentService _departmentService = DepartmentService(
    firestore: FirebaseFirestore.instance,
  );

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  List<String> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final departments = await _departmentService.getAllDepartments();
      setState(() {
        _departments = departments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Departmanlar yüklenirken hata: $e')),
        );
      }
    }
  }

  List<String> get _filteredDepartments {
    if (_searchQuery.isEmpty) {
      return _departments;
    }
    return _departments
        .where((department) =>
            department.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Departman Ara',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_filteredDepartments.isEmpty)
          const Center(
            child: Text(
              'Departman bulunamadı',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredDepartments.length,
            itemBuilder: (context, index) {
              final department = _filteredDepartments[index];
              final isSelected = department == widget.selectedDepartment;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
                  child: Text(
                    department.isNotEmpty ? department[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                title: Text(department),
                onTap: () => widget.onDepartmentSelected(department),
                selected: isSelected,
              );
            },
          ),
      ],
    );
  }
} 