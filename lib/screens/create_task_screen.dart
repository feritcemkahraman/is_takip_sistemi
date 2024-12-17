import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../constants/app_constants.dart';
import '../constants/color_constants.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _selectedPriority = 1;
  String _assignedTo = '';
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  List<PlatformFile> _selectedFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final users = await userService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcılar yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsersByDepartment(String? department) {
    setState(() {
      if (department == null) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) => user.department == department).toList();
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.files;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya seçilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final taskService = Provider.of<TaskService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        final task = TaskModel(
          id: '',
          title: _titleController.text,
          description: _descriptionController.text,
          assignedTo: _assignedTo,
          createdBy: currentUser.uid,
          createdAt: DateTime.now(),
          deadline: _selectedDate,
          status: 'pending',
          priority: _selectedPriority,
          attachments: _selectedFiles.map((file) => file.path!).toList(),
          metadata: {},
        );

        try {
          await taskService.createTask(task);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Görev başarıyla oluşturuldu')),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hata oluştu: $e')),
            );
          }
        }
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yeni Görev Oluştur',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorConstants.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _titleController,
                labelText: 'Görev Başlığı',
                prefixIcon: const Icon(Icons.title),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir başlık girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Görev Açıklaması',
                prefixIcon: const Icon(Icons.description),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir açıklama girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Son Tarih'),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Departman',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Tüm Departmanlar'),
                  ),
                  ...AppConstants.departments.map((department) {
                    return DropdownMenuItem(
                      value: department,
                      child: Text(department),
                    );
                  }).toList(),
                ],
                onChanged: _filterUsersByDepartment,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserModel>(
                decoration: const InputDecoration(
                  labelText: 'Görevli',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: _filteredUsers.map((user) {
                  return DropdownMenuItem(
                    value: user,
                    child: Text('${user.name} (${user.department})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _assignedTo = value!.id;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Görevli seçimi gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Öncelik',
                  border: OutlineInputBorder(),
                ),
                value: _selectedPriority,
                items: const [
                  DropdownMenuItem(
                    value: 1,
                    child: Text('Düşük'),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text('Orta'),
                  ),
                  DropdownMenuItem(
                    value: 3,
                    child: Text('Yüksek'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(
                  _selectedFiles.isEmpty
                      ? 'Dosya Ekle'
                      : '${_selectedFiles.length} dosya seçildi',
                ),
                trailing: const Icon(Icons.chevron_right),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                onTap: _pickFiles,
              ),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: _selectedFiles.map((file) {
                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(file.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedFiles.remove(file);
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              CustomButton(
                text: 'Görevi Oluştur',
                onPressed: _isLoading ? null : _createTask,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
