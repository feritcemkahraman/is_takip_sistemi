import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({Key? key}) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assigneeController = TextEditingController();
  final _authService = AuthService();
  final _taskService = TaskService();
  final _storage = FirebaseStorage.instance;

  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;
  List<UserModel> _employees = [];
  List<UserModel> _filteredEmployees = [];
  UserModel? _selectedEmployee;
  List<File> _selectedFiles = [];
  String _selectedPriority = AppConstants.taskPriorityNormal;
  String _selectedDepartment = '';

  final List<String> _departments = [
    'Satış / Pazarlama',
    'Mühendislik Departmanı',
    'Teknik Ekip',
    'Muhasebe',
    'İnsan Kaynakları',
    'Yazılım / PR',
  ];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    final snapshot = await _authService.getEmployees();
    setState(() {
      _employees = snapshot;
      _filterEmployees();
    });
  }

  void _filterEmployees() {
    setState(() {
      if (_selectedDepartment.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees
            .where((employee) => employee.department == _selectedDepartment)
            .toList();
      }
      // Seçili çalışanın departmanı değişirse, seçimi temizle
      if (_selectedEmployee != null &&
          _selectedEmployee!.department != _selectedDepartment) {
        _selectedEmployee = null;
        _assigneeController.clear();
      }
    });
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _selectedFiles.addAll(
          result.paths.where((path) => path != null).map((path) => File(path!)),
        );
      });
    }
  }

  Future<List<TaskAttachment>> _uploadFiles(String taskId) async {
    final attachments = <TaskAttachment>[];
    final currentUser = await _authService.getCurrentUser();

    for (final file in _selectedFiles) {
      final fileName = file.path.split('/').last;
      final ref = _storage.ref().child('tasks/$taskId/$fileName');
      
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      attachments.add(TaskAttachment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: fileName,
        fileUrl: downloadUrl,
        fileType: fileName.split('.').last,
        uploadedAt: DateTime.now(),
        uploadedBy: currentUser?.uid ?? '',
      ));
    }
    
    return attachments;
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir çalışan seçin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return;

      // Önce görevi oluştur
      final task = await _taskService.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignedTo: _selectedEmployee!.uid,
        assignedBy: currentUser.uid,
        dueDate: _dueDate,
        priority: _selectedPriority,
      );

      // Dosyaları yükle ve görevi güncelle
      if (_selectedFiles.isNotEmpty) {
        final attachments = await _uploadFiles(task.id);
        await _taskService.updateTask(
          task.copyWith(attachments: attachments),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görev başarıyla oluşturuldu')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Görev Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                label: AppConstants.labelTitle,
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Başlık gerekli';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: AppConstants.labelDescription,
                controller: _descriptionController,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Açıklama gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDepartment.isEmpty ? null : _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Departman',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                items: _departments.map((String department) {
                  return DropdownMenuItem<String>(
                    value: department,
                    child: Text(department),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDepartment = newValue ?? '';
                    _filterEmployees();
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir departman seçin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TypeAheadFormField<UserModel>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _assigneeController,
                  decoration: const InputDecoration(
                    labelText: 'Atanan Kişi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  enabled: _selectedDepartment.isNotEmpty,
                ),
                suggestionsCallback: (pattern) {
                  return _filteredEmployees.where((employee) =>
                    employee.name.toLowerCase().contains(pattern.toLowerCase())
                  ).toList();
                },
                itemBuilder: (context, employee) {
                  return ListTile(
                    title: Text(employee.name),
                    subtitle: Text(employee.department),
                  );
                },
                onSuggestionSelected: (employee) {
                  setState(() {
                    _selectedEmployee = employee;
                    _assigneeController.text = employee.name;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir çalışan seçin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Bitiş Tarihi'),
                subtitle: Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(_dueDate),
                ),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                ),
                onTap: _selectDueDate,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Dosya Ekle'),
                subtitle: Text(
                  _selectedFiles.isEmpty
                      ? 'Henüz dosya seçilmedi'
                      : '${_selectedFiles.length} dosya seçildi',
                ),
                trailing: const Icon(Icons.attach_file),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                ),
                onTap: _pickFiles,
              ),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seçilen Dosyalar:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_selectedFiles.length, (index) {
                        final file = _selectedFiles[index];
                        return ListTile(
                          dense: true,
                          title: Text(file.path.split('/').last),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedFiles.removeAt(index);
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Öncelik Seviyesi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: AppConstants.taskPriorityLabels.entries.map((priority) {
                        return Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              priority.value,
                              style: TextStyle(
                                color: Color(AppConstants.taskPriorityColors[priority.key]!),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            value: priority.key,
                            groupValue: _selectedPriority,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedPriority = value;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: AppConstants.buttonSave,
                onPressed: _createTask,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
