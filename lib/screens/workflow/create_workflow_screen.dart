import 'package:flutter/material.dart';
import '../../models/workflow_model.dart';
import '../../services/workflow_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';

class CreateWorkflowScreen extends StatefulWidget {
  const CreateWorkflowScreen({Key? key}) : super(key: key);

  @override
  State<CreateWorkflowScreen> createState() => _CreateWorkflowScreenState();
}

class _CreateWorkflowScreenState extends State<CreateWorkflowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workflowService = WorkflowService();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final List<WorkflowStep> _steps = [];
  final List<WorkflowCondition> _conditions = [];
  final List<ParallelWorkflow> _parallelFlows = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkflow() async {
    if (!_formKey.currentState!.validate()) return;
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir adım eklemelisiniz')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _workflowService.createWorkflow(
        title: _titleController.text,
        description: _descriptionController.text,
        createdBy: 'current_user_id', // TODO: Gerçek kullanıcı ID'si eklenecek
        steps: _steps,
        conditions: _conditions,
        parallelFlows: _parallelFlows,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İş akışı başarıyla oluşturuldu')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addStep() {
    showDialog(
      context: context,
      builder: (context) => _AddStepDialog(
        onAdd: (step) {
          setState(() => _steps.add(step));
        },
      ),
    );
  }

  void _addCondition() {
    showDialog(
      context: context,
      builder: (context) => _AddConditionDialog(
        onAdd: (condition) {
          setState(() => _conditions.add(condition));
        },
      ),
    );
  }

  void _addParallelFlow() {
    showDialog(
      context: context,
      builder: (context) => _AddParallelFlowDialog(
        onAdd: (flow) {
          setState(() => _parallelFlows.add(flow));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Yeni İş Akışı',
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveWorkflow,
            ),
        ],
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
                label: 'Başlık',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Başlık gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Açıklama',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Açıklama gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildStepsList(),
              const SizedBox(height: 24),
              _buildConditionsList(),
              const SizedBox(height: 24),
              _buildParallelFlowsList(),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_step',
            onPressed: _addStep,
            child: const Icon(Icons.add_task),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add_condition',
            onPressed: _addCondition,
            child: const Icon(Icons.rule),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add_parallel',
            onPressed: _addParallelFlow,
            child: const Icon(Icons.call_split),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adımlar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (_steps.isEmpty)
          const Card(
            child: ListTile(
              title: Text('Henüz adım eklenmemiş'),
              subtitle: Text('Yeni adım eklemek için + butonuna tıklayın'),
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
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(step.title),
                  subtitle: Text(step.description),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() => _steps.removeAt(index));
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildConditionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Koşullar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (_conditions.isEmpty)
          const Card(
            child: ListTile(
              title: Text('Henüz koşul eklenmemiş'),
              subtitle: Text('Yeni koşul eklemek için + butonuna tıklayın'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _conditions.length,
            itemBuilder: (context, index) {
              final condition = _conditions[index];
              String operatorText = '';
              switch (condition.operator) {
                case WorkflowCondition.operatorEquals:
                  operatorText = '=';
                  break;
                case WorkflowCondition.operatorNotEquals:
                  operatorText = '≠';
                  break;
                case WorkflowCondition.operatorGreaterThan:
                  operatorText = '>';
                  break;
                case WorkflowCondition.operatorLessThan:
                  operatorText = '<';
                  break;
                case WorkflowCondition.operatorContains:
                  operatorText = 'içerir';
                  break;
                case WorkflowCondition.operatorNotContains:
                  operatorText = 'içermez';
                  break;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text('${condition.field} $operatorText ${condition.value}'),
                  subtitle: Text('Aksiyon: ${condition.action}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() => _conditions.removeAt(index));
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildParallelFlowsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paralel Akışlar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (_parallelFlows.isEmpty)
          const Card(
            child: ListTile(
              title: Text('Henüz paralel akış eklenmemiş'),
              subtitle: Text('Yeni paralel akış eklemek için + butonuna tıklayın'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _parallelFlows.length,
            itemBuilder: (context, index) {
              final flow = _parallelFlows[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ExpansionTile(
                  title: Text(flow.title),
                  subtitle: Text(
                    flow.waitForAll ? 'Tümünü Bekle' : 'Herhangi Birini Bekle',
                  ),
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: flow.steps.length,
                      itemBuilder: (context, stepIndex) {
                        final step = flow.steps[stepIndex];
                        return ListTile(
                          title: Text(step.title),
                          subtitle: Text(step.description),
                        );
                      },
                    ),
                  ],
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() => _parallelFlows.removeAt(index));
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _AddStepDialog extends StatefulWidget {
  final void Function(WorkflowStep) onAdd;

  const _AddStepDialog({required this.onAdd});

  @override
  State<_AddStepDialog> createState() => _AddStepDialogState();
}

class _AddStepDialogState extends State<_AddStepDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = WorkflowStep.typeTask;
  String _assignedTo = '';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addStep() {
    if (!_formKey.currentState!.validate()) return;

    final step = WorkflowStep(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      type: _type,
      assignedTo: _assignedTo,
      status: WorkflowStep.statusPending,
    );

    widget.onAdd(step);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adım Ekle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _titleController,
              label: 'Başlık',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Başlık gereklidir';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              label: 'Açıklama',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Açıklama gereklidir';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Tip',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: WorkflowStep.typeTask,
                  child: Text('Görev'),
                ),
                DropdownMenuItem(
                  value: WorkflowStep.typeApproval,
                  child: Text('Onay'),
                ),
                DropdownMenuItem(
                  value: WorkflowStep.typeNotification,
                  child: Text('Bildirim'),
                ),
              ],
              onChanged: (value) {
                setState(() => _type = value!);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Atanan Kişi',
              onChanged: (value) => _assignedTo = value,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Atanan kişi gereklidir';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _addStep,
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

class _AddConditionDialog extends StatefulWidget {
  final void Function(WorkflowCondition) onAdd;

  const _AddConditionDialog({required this.onAdd});

  @override
  State<_AddConditionDialog> createState() => _AddConditionDialogState();
}

class _AddConditionDialogState extends State<_AddConditionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fieldController = TextEditingController();
  final _valueController = TextEditingController();
  String _operator = WorkflowCondition.operatorEquals;
  String _action = WorkflowCondition.actionContinue;

  @override
  void dispose() {
    _fieldController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _addCondition() {
    if (!_formKey.currentState!.validate()) return;

    final condition = WorkflowCondition(
      field: _fieldController.text,
      operator: _operator,
      value: _valueController.text,
      action: _action,
    );

    widget.onAdd(condition);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Koşul Ekle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _fieldController,
              label: 'Alan',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Alan gereklidir';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _operator,
              decoration: const InputDecoration(
                labelText: 'Operatör',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: WorkflowCondition.operatorEquals,
                  child: Text('Eşittir'),
                ),
                DropdownMenuItem(
                  value: WorkflowCondition.operatorNotEquals,
                  child: Text('Eşit Değildir'),
                ),
                DropdownMenuItem(
                  value: WorkflowCondition.operatorGreaterThan,
                  child: Text('Büyüktür'),
                ),
                DropdownMenuItem(
                  value: WorkflowCondition.operatorLessThan,
                  child: Text('Küçüktür'),
                ),
                DropdownMenuItem(
                  value: WorkflowCondition.operatorContains,
                  child: Text('İçerir'),
                ),
                DropdownMenuItem(
                  value: WorkflowCondition.operatorNotContains,
                  child: Text('İçermez'),
                ),
              ],
              onChanged: (value) {
                setState(() => _operator = value!);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _valueController,
              label: 'Değer',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Değer gereklidir';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _action,
              decoration: const InputDecoration(
                labelText: 'Aksiyon',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: WorkflowCondition.actionContinue,
                  child: Text('Devam Et'),
                ),
                DropdownMenuItem(
                  value: WorkflowCondition.actionStop,
                  child: Text('Durdur'),
                ),
                DropdownMenuItem(
                  value: WorkflowCondition.actionSkip,
                  child: Text('Atla'),
                ),
              ],
              onChanged: (value) {
                setState(() => _action = value!);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _addCondition,
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

class _AddParallelFlowDialog extends StatefulWidget {
  final void Function(ParallelWorkflow) onAdd;

  const _AddParallelFlowDialog({required this.onAdd});

  @override
  State<_AddParallelFlowDialog> createState() => _AddParallelFlowDialogState();
}

class _AddParallelFlowDialogState extends State<_AddParallelFlowDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final List<WorkflowStep> _steps = [];
  bool _waitForAll = true;
  int _timeoutSeconds = 300; // 5 dakika

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addStep() {
    showDialog(
      context: context,
      builder: (context) => _AddStepDialog(
        onAdd: (step) {
          setState(() => _steps.add(step));
        },
      ),
    );
  }

  void _addParallelFlow() {
    if (!_formKey.currentState!.validate()) return;
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir adım eklemelisiniz')),
      );
      return;
    }

    final flow = ParallelWorkflow(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      steps: _steps,
      waitForAll: _waitForAll,
      timeout: Duration(seconds: _timeoutSeconds),
      status: ParallelWorkflow.statusPending,
    );

    widget.onAdd(flow);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paralel Akış Ekle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _titleController,
                label: 'Başlık',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Başlık gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Tüm Adımları Bekle'),
                subtitle: Text(
                  _waitForAll
                      ? 'Tüm adımlar tamamlanana kadar bekle'
                      : 'Herhangi bir adım tamamlandığında devam et',
                ),
                value: _waitForAll,
                onChanged: (value) {
                  setState(() => _waitForAll = value);
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Zaman Aşımı (saniye)',
                initialValue: _timeoutSeconds.toString(),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Zaman aşımı gereklidir';
                  }
                  final timeout = int.tryParse(value);
                  if (timeout == null || timeout <= 0) {
                    return 'Geçerli bir sayı giriniz';
                  }
                  return null;
                },
                onChanged: (value) {
                  final timeout = int.tryParse(value);
                  if (timeout != null && timeout > 0) {
                    _timeoutSeconds = timeout;
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Adımlar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_steps.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('Henüz adım eklenmemiş'),
                    subtitle: Text('Yeni adım eklemek için + butonuna tıklayın'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(step.title),
                        subtitle: Text(step.description),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() => _steps.removeAt(index));
                          },
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addStep,
                icon: const Icon(Icons.add),
                label: const Text('Adım Ekle'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _addParallelFlow,
          child: const Text('Ekle'),
        ),
      ],
    );
  }
} 