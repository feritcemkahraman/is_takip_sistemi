import 'package:flutter/material.dart';
import '../../models/workflow_model.dart';
import '../../services/workflow_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import 'package:timeline_tile/timeline_tile.dart';

class WorkflowDetailScreen extends StatefulWidget {
  final String workflowId;

  const WorkflowDetailScreen({Key? key, required this.workflowId})
      : super(key: key);

  @override
  State<WorkflowDetailScreen> createState() => _WorkflowDetailScreenState();
}

class _WorkflowDetailScreenState extends State<WorkflowDetailScreen> {
  final WorkflowService _workflowService = WorkflowService();
  late Future<WorkflowModel?> _workflowFuture;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _workflowFuture = _workflowService.getWorkflow(widget.workflowId);
    try {
      _statistics = await _workflowService.getWorkflowStatistics();
      if (mounted) setState(() {});
    } catch (e) {
      // İstatistik yüklenemezse gösterme
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'İş Akışı Detayı',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadData();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<WorkflowModel?>(
        future: _workflowFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Hata: ${snapshot.error}'),
            );
          }

          final workflow = snapshot.data;
          if (workflow == null) {
            return const Center(
              child: Text('İş akışı bulunamadı'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(workflow),
                const SizedBox(height: 24),
                if (_statistics != null) _buildStatistics(),
                const SizedBox(height: 24),
                _buildStepsTimeline(workflow),
                if (workflow.conditions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildConditions(workflow),
                ],
                if (workflow.parallelFlows.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildParallelFlows(workflow),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(WorkflowModel workflow) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    workflow.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                _buildStatusChip(workflow.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              workflow.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Oluşturan: ${workflow.createdBy}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  _formatDate(workflow.createdAt),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İstatistikler',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Toplam',
                  _statistics!['total'].toString(),
                  Icons.list,
                ),
                _buildStatItem(
                  'Tamamlanan',
                  _statistics!['completed'].toString(),
                  Icons.check_circle_outline,
                ),
                _buildStatItem(
                  'Aktif',
                  _statistics!['active'].toString(),
                  Icons.play_circle_outline,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Koşullu',
                  _statistics!['withConditions'].toString(),
                  Icons.rule,
                ),
                _buildStatItem(
                  'Paralel',
                  _statistics!['withParallelFlows'].toString(),
                  Icons.call_split,
                ),
                _buildStatItem(
                  'Ort. Süre',
                  '${_statistics!['averageCompletionTime'].toStringAsFixed(1)} dk',
                  Icons.timer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStepsTimeline(WorkflowModel workflow) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adımlar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workflow.steps.length,
              itemBuilder: (context, index) {
                final step = workflow.steps[index];
                final isFirst = index == 0;
                final isLast = index == workflow.steps.length - 1;

                return TimelineTile(
                  isFirst: isFirst,
                  isLast: isLast,
                  indicatorStyle: IndicatorStyle(
                    width: 30,
                    height: 30,
                    indicator: _buildStepIndicator(step),
                  ),
                  beforeLineStyle: LineStyle(
                    color: _getStepColor(step.status).withOpacity(0.3),
                  ),
                  endChild: _buildStepContent(step, index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(WorkflowStep step) {
    final color = _getStepColor(step.status);
    IconData icon;

    switch (step.status) {
      case WorkflowStep.statusCompleted:
        icon = Icons.check;
        break;
      case WorkflowStep.statusInProgress:
        icon = Icons.play_arrow;
        break;
      case WorkflowStep.statusCancelled:
        icon = Icons.close;
        break;
      default:
        icon = Icons.circle;
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildStepContent(WorkflowStep step, int index) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: Text('${index + 1}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      step.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              _buildStepStatusChip(step.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16),
              const SizedBox(width: 4),
              Text(
                'Atanan: ${step.assignedTo}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (step.dueDate != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.event, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Bitiş: ${_formatDate(step.dueDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditions(WorkflowModel workflow) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rule),
                const SizedBox(width: 8),
                Text(
                  'Koşullar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workflow.conditions.length,
              itemBuilder: (context, index) {
                final condition = workflow.conditions[index];
                return _buildConditionItem(condition);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionItem(WorkflowCondition condition) {
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

    Color actionColor;
    switch (condition.action) {
      case WorkflowCondition.actionContinue:
        actionColor = Colors.green;
        break;
      case WorkflowCondition.actionStop:
        actionColor = Colors.red;
        break;
      case WorkflowCondition.actionSkip:
        actionColor = Colors.orange;
        break;
      default:
        actionColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: const Icon(Icons.rule_folder),
        title: Text('${condition.field} $operatorText ${condition.value}'),
        subtitle: Text(
          'Aksiyon: ${condition.action}',
          style: TextStyle(color: actionColor),
        ),
        trailing: Icon(
          _getActionIcon(condition.action),
          color: actionColor,
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case WorkflowCondition.actionContinue:
        return Icons.play_arrow;
      case WorkflowCondition.actionStop:
        return Icons.stop;
      case WorkflowCondition.actionSkip:
        return Icons.skip_next;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildParallelFlows(WorkflowModel workflow) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.call_split),
                const SizedBox(width: 8),
                Text(
                  'Paralel Akışlar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workflow.parallelFlows.length,
              itemBuilder: (context, index) {
                final flow = workflow.parallelFlows[index];
                return _buildParallelFlowItem(flow);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParallelFlowItem(ParallelWorkflow flow) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        leading: const Icon(Icons.account_tree),
        title: Text(flow.title),
        subtitle: Row(
          children: [
            Icon(
              flow.waitForAll ? Icons.all_inclusive : Icons.first_page,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              flow.waitForAll ? 'Tümünü Bekle' : 'Herhangi Birini Bekle',
            ),
            const SizedBox(width: 16),
            const Icon(Icons.timer, size: 16),
            const SizedBox(width: 4),
            Text('${flow.timeout.inMinutes} dk'),
          ],
        ),
        trailing: _buildParallelFlowStatus(flow.status),
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: flow.steps.length,
            itemBuilder: (context, index) {
              final step = flow.steps[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(step.title),
                subtitle: Text(step.description),
                trailing: _buildStepStatusChip(step.status),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildParallelFlowStatus(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case ParallelWorkflow.statusPending:
        color = Colors.grey;
        icon = Icons.hourglass_empty;
        break;
      case ParallelWorkflow.statusInProgress:
        color = Colors.blue;
        icon = Icons.play_circle;
        break;
      case ParallelWorkflow.statusCompleted:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case ParallelWorkflow.statusCancelled:
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case WorkflowModel.statusDraft:
        color = Colors.grey;
        text = 'Taslak';
        break;
      case WorkflowModel.statusActive:
        color = Colors.blue;
        text = 'Aktif';
        break;
      case WorkflowModel.statusCompleted:
        color = Colors.green;
        text = 'Tamamlandı';
        break;
      case WorkflowModel.statusCancelled:
        color = Colors.red;
        text = 'İptal Edildi';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Chip(
      label: Text(text),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
    );
  }

  Widget _buildStepStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case WorkflowStep.statusPending:
        color = Colors.grey;
        text = 'Bekliyor';
        break;
      case WorkflowStep.statusInProgress:
        color = Colors.blue;
        text = 'Devam Ediyor';
        break;
      case WorkflowStep.statusCompleted:
        color = Colors.green;
        text = 'Tamamlandı';
        break;
      case WorkflowStep.statusCancelled:
        color = Colors.red;
        text = 'İptal Edildi';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Chip(
      label: Text(text),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
    );
  }

  Color _getStepColor(String status) {
    switch (status) {
      case WorkflowStep.statusPending:
        return Colors.grey;
      case WorkflowStep.statusInProgress:
        return Colors.blue;
      case WorkflowStep.statusCompleted:
        return Colors.green;
      case WorkflowStep.statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 