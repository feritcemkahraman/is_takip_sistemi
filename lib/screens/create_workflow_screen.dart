import 'package:flutter/material.dart';
import '../models/workflow_model.dart';
import '../services/workflow_service.dart';
import '../services/auth_service.dart';
import '../widgets/file_upload_widget.dart';
import '../widgets/user_selector_widget.dart';

class CreateWorkflowScreen extends StatefulWidget {
  final WorkflowModel? template;

  const CreateWorkflowScreen({
    super.key,
    this.template,
  });

  @override
  State<CreateWorkflowScreen> createState() => _CreateWorkflowScreenState();
}

class _CreateWorkflowScreenState extends State<CreateWorkflowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _workflowService = WorkflowService();
  final _authService = AuthService();
  
  String _type = WorkflowModel.typeTask;
  int _priority = WorkflowModel.priorityNormal;
  DateTime? _deadline;
  List<WorkflowStep> _steps = [];
  bool _isTemplate = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _loadTemplate();
    }
  }

  void _loadTemplate() {
    final template = widget.template!;
    _titleController.text = template.title;
    _descriptionController.text = template.description;
    _type = template.type;
    _priority = template.priority;
    _deadline = template.deadline;
    _steps = List.from(template.steps);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template != null ? 'Şablondan Oluştur' : 'Yeni İş Akışı'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Başlık',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Başlık gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        border: OutlineInputBorder(),
                      ),
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
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Tür',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: WorkflowModel.typeApproval,
                          child: const Text('Onay'),
                        ),
                        DropdownMenuItem(
                          value: WorkflowModel.typeTask,
                          child: const Text('Görev'),
                        ),
                        DropdownMenuItem(
                          value: WorkflowModel.typeDocument,
                          child: const Text('Döküman'),
                        ),
                        DropdownMenuItem(
                          value: WorkflowModel.typeRequest,
                          child: const Text('Talep'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _type = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Öncelik',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: WorkflowModel.priorityLow,
                          child: const Text('Düşük'),
                        ),
                        DropdownMenuItem(
                          value: WorkflowModel.priorityNormal,
                          child: const Text('Normal'),
                        ),
                        DropdownMenuItem(
                          value: WorkflowModel.priorityHigh,
                          child: const Text('Yüksek'),
                        ),
                        DropdownMenuItem(
                          value: WorkflowModel.priorityUrgent,
                          child: const Text('Acil'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _priority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Son Tarih'),
                      subtitle: Text(_deadline?.toString() ?? 'Seçilmedi'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _selectDeadline,
                          ),
                          if (_deadline != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _deadline = null),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStepsList(),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Şablon Olarak Kaydet'),
                      value: _isTemplate,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _isTemplate = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createWorkflow,
        icon: const Icon(Icons.save),
        label: const Text('Kaydet'),
      ),
    );
  }

  Widget _buildStepsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Adımlar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addStep,
            ),
          ],
        ),
        if (_steps.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Henüz adım eklenmedi'),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _steps.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _steps.removeAt(oldIndex);
                _steps.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final step = _steps[index];
              return Card(
                key: ValueKey(step.id),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(step.title),
                  subtitle: Text(step.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editStep(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteStep(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    if (time == null) return;

    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _addStep() async {
    final step = await _showStepDialog();
    if (step != null) {
      setState(() => _steps.add(step));
    }
  }

  Future<void> _editStep(int index) async {
    final step = await _showStepDialog(step: _steps[index]);
    if (step != null) {
      setState(() => _steps[index] = step);
    }
  }

  void _deleteStep(int index) {
    setState(() => _steps.removeAt(index));
  }

  Future<WorkflowStep?> _showStepDialog({WorkflowStep? step}) async {
    final titleController = TextEditingController(text: step?.title);
    final descriptionController = TextEditingController(text: step?.description);
    List<String> selectedUserIds = step?.assignedTo != null ? [step!.assignedTo] : [];
    String selectedType = step?.type ?? WorkflowStep.typeTask;
    Map<String, dynamic>? conditions = step?.conditions;
    List<String>? trueSteps = step?.trueSteps;
    List<String>? falseSteps = step?.falseSteps;
    List<WorkflowStep>? parallelSteps = step?.parallelSteps;
    Map<String, dynamic>? loopCondition = step?.loopCondition;
    List<WorkflowStep>? loopSteps = step?.loopSteps;

    return showDialog<WorkflowStep>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  step == null ? 'Adım Ekle' : 'Adım Düzenle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Adım Tipi',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: WorkflowStep.typeTask,
                      child: const Text('Görev'),
                    ),
                    DropdownMenuItem(
                      value: WorkflowStep.typeApproval,
                      child: const Text('Onay'),
                    ),
                    DropdownMenuItem(
                      value: WorkflowStep.typeCondition,
                      child: const Text('Koşul'),
                    ),
                    DropdownMenuItem(
                      value: WorkflowStep.typeParallel,
                      child: const Text('Paralel'),
                    ),
                    DropdownMenuItem(
                      value: WorkflowStep.typeLoop,
                      child: const Text('Döngü'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedType = value;
                      if (mounted) setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (selectedType == WorkflowStep.typeCondition)
                  _buildConditionFields(
                    conditions: conditions,
                    onConditionsChanged: (value) => conditions = value,
                    trueSteps: trueSteps,
                    onTrueStepsChanged: (value) => trueSteps = value,
                    falseSteps: falseSteps,
                    onFalseStepsChanged: (value) => falseSteps = value,
                  )
                else if (selectedType == WorkflowStep.typeParallel)
                  _buildParallelStepsField(
                    parallelSteps: parallelSteps,
                    onParallelStepsChanged: (value) => parallelSteps = value,
                  )
                else if (selectedType == WorkflowStep.typeLoop)
                  _buildLoopFields(
                    loopCondition: loopCondition,
                    onLoopConditionChanged: (value) => loopCondition = value,
                    loopSteps: loopSteps,
                    onLoopStepsChanged: (value) => loopSteps = value,
                  )
                else
                  SizedBox(
                    height: 300,
                    child: UserSelectorWidget(
                      selectedUserIds: selectedUserIds,
                      onUsersSelected: (userIds) {
                        selectedUserIds = userIds;
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (titleController.text.isEmpty ||
                            descriptionController.text.isEmpty ||
                            (selectedType != WorkflowStep.typeCondition &&
                                selectedType != WorkflowStep.typeParallel &&
                                selectedType != WorkflowStep.typeLoop &&
                                selectedUserIds.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tüm alanları doldurun'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(
                          context,
                          WorkflowStep(
                            id: step?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleController.text,
                            description: descriptionController.text,
                            type: selectedType,
                            assignedTo: selectedUserIds.isNotEmpty ? selectedUserIds.first : '',
                            status: step?.status ?? WorkflowStep.statusPending,
                            isActive: step?.isActive ?? true,
                            conditions: conditions,
                            trueSteps: trueSteps,
                            falseSteps: falseSteps,
                            parallelSteps: parallelSteps,
                            loopCondition: loopCondition,
                            loopSteps: loopSteps,
                          ),
                        );
                      },
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConditionFields({
    Map<String, dynamic>? conditions,
    required Function(Map<String, dynamic>?) onConditionsChanged,
    List<String>? trueSteps,
    required Function(List<String>?) onTrueStepsChanged,
    List<String>? falseSteps,
    required Function(List<String>?) onFalseStepsChanged,
  }) {
    final conditionTypeController = TextEditingController(
      text: conditions?['type'] ?? 'equals',
    );
    final fieldController = TextEditingController(
      text: conditions?['field'] ?? '',
    );
    final valueController = TextEditingController(
      text: conditions?['value']?.toString() ?? '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: conditionTypeController.text,
          decoration: const InputDecoration(
            labelText: 'Koşul Tipi',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'equals', child: Text('Eşittir')),
            DropdownMenuItem(value: 'notEquals', child: Text('Eşit Değildir')),
            DropdownMenuItem(value: 'greaterThan', child: Text('Büyüktür')),
            DropdownMenuItem(value: 'lessThan', child: Text('Küçüktür')),
            DropdownMenuItem(value: 'contains', child: Text('İçerir')),
          ],
          onChanged: (value) {
            if (value != null) {
              conditionTypeController.text = value;
              onConditionsChanged({
                'type': value,
                'field': fieldController.text,
                'value': valueController.text,
              });
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: fieldController,
          decoration: const InputDecoration(
            labelText: 'Alan',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            onConditionsChanged({
              'type': conditionTypeController.text,
              'field': value,
              'value': valueController.text,
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: valueController,
          decoration: const InputDecoration(
            labelText: 'Değer',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            onConditionsChanged({
              'type': conditionTypeController.text,
              'field': fieldController.text,
              'value': value,
            });
          },
        ),
        const SizedBox(height: 16),
        const Text('Koşul Doğruysa:'),
        Wrap(
          spacing: 8,
          children: _steps
              .map((step) => FilterChip(
                    label: Text(step.title),
                    selected: trueSteps?.contains(step.id) ?? false,
                    onSelected: (selected) {
                      final newTrueSteps = List<String>.from(trueSteps ?? []);
                      if (selected) {
                        newTrueSteps.add(step.id);
                      } else {
                        newTrueSteps.remove(step.id);
                      }
                      onTrueStepsChanged(newTrueSteps);
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        const Text('Koşul Yanlışsa:'),
        Wrap(
          spacing: 8,
          children: _steps
              .map((step) => FilterChip(
                    label: Text(step.title),
                    selected: falseSteps?.contains(step.id) ?? false,
                    onSelected: (selected) {
                      final newFalseSteps = List<String>.from(falseSteps ?? []);
                      if (selected) {
                        newFalseSteps.add(step.id);
                      } else {
                        newFalseSteps.remove(step.id);
                      }
                      onFalseStepsChanged(newFalseSteps);
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildParallelStepsField({
    List<WorkflowStep>? parallelSteps,
    required Function(List<WorkflowStep>?) onParallelStepsChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Paralel Adımlar:'),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: parallelSteps?.length ?? 0,
          itemBuilder: (context, index) {
            final step = parallelSteps![index];
            return ListTile(
              title: Text(step.title),
              subtitle: Text(step.description),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  final newSteps = List<WorkflowStep>.from(parallelSteps);
                  newSteps.removeAt(index);
                  onParallelStepsChanged(newSteps);
                  setState(() {});
                },
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () async {
            final step = await _showStepDialog();
            if (step != null) {
              final newSteps = List<WorkflowStep>.from(parallelSteps ?? []);
              newSteps.add(step);
              onParallelStepsChanged(newSteps);
              setState(() {});
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Paralel Adım Ekle'),
        ),
      ],
    );
  }

  Widget _buildLoopFields({
    Map<String, dynamic>? loopCondition,
    required Function(Map<String, dynamic>?) onLoopConditionChanged,
    List<WorkflowStep>? loopSteps,
    required Function(List<WorkflowStep>?) onLoopStepsChanged,
  }) {
    final typeController = TextEditingController(
      text: loopCondition?['type'] ?? 'count',
    );
    final maxCountController = TextEditingController(
      text: loopCondition?['maxCount']?.toString() ?? '1',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: typeController.text,
          decoration: const InputDecoration(
            labelText: 'Döngü Tipi',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'count', child: Text('Sayaç')),
            DropdownMenuItem(value: 'condition', child: Text('Koşul')),
          ],
          onChanged: (value) {
            if (value != null) {
              typeController.text = value;
              onLoopConditionChanged({
                'type': value,
                'maxCount': int.tryParse(maxCountController.text) ?? 1,
              });
            }
          },
        ),
        const SizedBox(height: 16),
        if (typeController.text == 'count')
          TextField(
            controller: maxCountController,
            decoration: const InputDecoration(
              labelText: 'Maksimum Tekrar',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              onLoopConditionChanged({
                'type': typeController.text,
                'maxCount': int.tryParse(value) ?? 1,
              });
            },
          ),
        const SizedBox(height: 16),
        const Text('Döngü Adımları:'),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: loopSteps?.length ?? 0,
          itemBuilder: (context, index) {
            final step = loopSteps![index];
            return ListTile(
              title: Text(step.title),
              subtitle: Text(step.description),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  final newSteps = List<WorkflowStep>.from(loopSteps);
                  newSteps.removeAt(index);
                  onLoopStepsChanged(newSteps);
                  setState(() {});
                },
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () async {
            final step = await _showStepDialog();
            if (step != null) {
              final newSteps = List<WorkflowStep>.from(loopSteps ?? []);
              newSteps.add(step);
              onLoopStepsChanged(newSteps);
              setState(() {});
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Döngü Adımı Ekle'),
        ),
      ],
    );
  }

  Future<void> _createWorkflow() async {
    if (!_formKey.currentState!.validate()) return;
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir adım eklemelisiniz')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      final workflow = WorkflowModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        type: _type,
        status: WorkflowModel.statusDraft,
        createdBy: user.uid,
        createdAt: DateTime.now(),
        steps: _steps,
        priority: _priority,
        deadline: _deadline,
        isTemplate: _isTemplate,
      );

      await _workflowService.createWorkflow(workflow);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
} 