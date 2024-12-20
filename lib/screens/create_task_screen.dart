import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _selectedPriority = 1;
  String? _assignedTo;
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  List<PlatformFile> _selectedFiles = [];
  bool _isLoading = false;
  String? _selectedDepartment = '';
  late final UserService _userService;

  @override
  void initState() {
    super.initState();
    print('CreateTaskScreen initState çağrıldı');
    _userService = Provider.of<UserService>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      print('_loadUsers başladı');
      setState(() => _isLoading = true);
      
      final users = await _userService.getAllUsers();
      print('Kullanıcılar yüklendi. Toplam: ${users.length}');
      print('Kullanıcı listesi: ${users.map((u) => '${u.name} (${u.department})').join(', ')}');
      
      if (mounted) {
        setState(() {
          _users = users;
          _filteredUsers = users;
          _isLoading = false;
          print('State güncellendi. _users: ${_users.length}, _filteredUsers: ${_filteredUsers.length}');
        });
      }
    } catch (e, stackTrace) {
      print('_loadUsers hatası: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
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
    print('_filterUsersByDepartment çağrıldı. Departman: $department');
    setState(() {
      _selectedDepartment = department;
      _assignedTo = null;  // Departman değiştiğinde seçili görevliyi sıfırla
      
      if (department == null || department.isEmpty) {
        print('Tüm kullanıcılar listeleniyor...');
        _filteredUsers = _users;
      } else {
        print('$department departmanındaki kullanıcılar filtreleniyor...');
        _filteredUsers = _users
          .where((user) => user.department == department)
          .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      }
      print('Filtrelenmiş kullanıcı sayısı: ${_filteredUsers.length}');
      if (_filteredUsers.isEmpty) {
        print('UYARI: $_selectedDepartment departmanında hiç kullanıcı yok!');
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
      try {
        setState(() => _isLoading = true);

        if (_assignedTo == null || _assignedTo!.isEmpty) {
          throw Exception('Lütfen bir görevli seçin');
        }

        final taskService = Provider.of<TaskService>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);
        final currentUser = await authService.getCurrentUserModel();

        if (currentUser == null) {
          throw Exception('Oturum açmış kullanıcı bulunamadı');
        }

        // Dosyaları yerel olarak kaydet
        List<String> attachmentPaths = [];
        if (_selectedFiles.isNotEmpty) {
          final localStorageService = LocalStorageService();
          final taskId = DateTime.now().millisecondsSinceEpoch.toString();

          for (var file in _selectedFiles) {
            if (file.path != null) {
              try {
                final savedPath = await localStorageService.saveTaskAttachment(
                  taskId,
                  file.name,
                  File(file.path!),
                );
                attachmentPaths.add(savedPath);
                print('Dosya kaydedildi: ${file.name}');
              } catch (e) {
                print('Dosya kaydedilemedi (${file.name}): $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${file.name} dosyası kaydedilemedi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          }
        }

        // Görevi oluştur
        await taskService.createTask(
          title: _titleController.text,
          description: _descriptionController.text,
          assignedTo: _assignedTo!,
          createdBy: currentUser.id,
          deadline: _selectedDate,
          priority: _selectedPriority,
          attachments: attachmentPaths,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushNamed('/tasks-screen');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Görev başarıyla oluşturuldu')),
          );
        }
      } catch (e) {
        print('Görev oluşturma hatası: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Görev oluşturulurken hata: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
                value: _selectedDepartment, // Seçili departmanı belirt
                items: [
                  const DropdownMenuItem(
                    value: '',  // null yerine boş string kullan
                    child: Text('Tüm Departmanlar'),
                  ),
                  ...AppConstants.departments.map((department) {
                    return DropdownMenuItem(
                      value: department,
                      child: Text(department),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  print('Seçilen departman: $value'); // Debug log
                  _filterUsersByDepartment(value!.isEmpty ? null : value); // Boş string kontrolü
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir departman seçin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Görevli',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                value: _assignedTo,
                items: _selectedDepartment == null || _selectedDepartment!.isEmpty
                    ? []
                    : _filteredUsers.isEmpty
                        ? [
                            DropdownMenuItem(
                              value: '',
                              enabled: false,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: const Text(
                                  'Seçilen departmanda görevli bulunmamaktadır',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          ]
                        : _filteredUsers.map((user) {
                            return DropdownMenuItem(
                              value: user.id,
                              child: Text('${user.name}'),
                            );
                          }).toList(),
                onChanged: _selectedDepartment == null || _selectedDepartment!.isEmpty || _filteredUsers.isEmpty
                    ? null
                    : (String? value) {
                        setState(() {
                          _assignedTo = value;
                        });
                      },
                icon: const Icon(Icons.arrow_drop_down),
                isDense: true,
                isExpanded: true,
                validator: (value) {
                  if (_selectedDepartment != null && 
                      !_selectedDepartment!.isEmpty && 
                      _filteredUsers.isNotEmpty && 
                      (value == null || value.isEmpty)) {
                    return 'Lütfen bir görevli seçin';
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
