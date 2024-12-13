import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';
import '../../models/task_model.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _dueDate;
  String _selectedPriority = 'normal';
  String _selectedDepartment = '';
  String _selectedAssignee = '';
  bool _isRecurring = false;
  String? _recurrenceType;
  bool _isLoading = false;

  final List<String> _priorities = ['high', 'normal', 'low'];
  final List<String> _recurrenceTypes = ['daily', 'weekly', 'monthly'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen başlangıç ve bitiş tarihi seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDepartment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir departman seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedAssignee.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir görevli seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final taskService = Provider.of<TaskService>(context, listen: false);
      final currentUser = await authService.getCurrentUserModel();

      if (currentUser == null) {
        throw 'Oturum açmış kullanıcı bulunamadı';
      }

      final task = TaskModel(
        id: '', // Firestore tarafından otomatik oluşturulacak
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignedTo: _selectedAssignee,
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
        startDate: _startDate!,
        dueDate: _dueDate!,
        priority: _selectedPriority,
        status: 'pending',
        department: _selectedDepartment,
        isRecurring: _isRecurring,
        recurrenceType: _isRecurring ? _recurrenceType : null,
        watchers: [currentUser.uid, _selectedAssignee],
      );

      await taskService.createTask(task);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Görev başarıyla oluşturuldu'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev oluşturulurken hata: $e'),
            backgroundColor: Colors.red,
          ),
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
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _titleController,
                labelText: 'Görev Başlığı',
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
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir açıklama girin';
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
                ),
                items: AppConstants.departments.map((String department) {
                  return DropdownMenuItem<String>(
                    value: department,
                    child: Text(department),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDepartment = newValue ?? '';
                    _selectedAssignee = ''; // Departman değişince görevliyi sıfırla
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Öncelik',
                  border: OutlineInputBorder(),
                ),
                items: _priorities.map((String priority) {
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Text(
                      priority == 'high'
                          ? 'Acil'
                          : priority == 'normal'
                              ? 'Normal'
                              : 'Düşük',
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPriority = newValue ?? 'normal';
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_startDate == null
                    ? 'Başlangıç Tarihi Seçin'
                    : 'Başlangıç: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _startDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Bitiş Tarihi'),
                subtitle: Text(
                  _dueDate == null
                      ? 'Tarih seçilmedi'
                      : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _dueDate = date);
                  }
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Tekrarlı Görev'),
                value: _isRecurring,
                onChanged: (bool value) {
                  setState(() {
                    _isRecurring = value;
                    if (!value) {
                      _recurrenceType = null;
                    }
                  });
                },
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _recurrenceType,
                  decoration: const InputDecoration(
                    labelText: 'Tekrar Sıklığı',
                    border: OutlineInputBorder(),
                  ),
                  items: _recurrenceTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type == 'daily'
                            ? 'Günlük'
                            : type == 'weekly'
                                ? 'Haftalık'
                                : 'Aylık',
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _recurrenceType = newValue;
                    });
                  },
                ),
              ],
              const SizedBox(height: 24),
              CustomButton(
                text: 'Görev Oluştur',
                onPressed: _isLoading ? null : _createTask,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
