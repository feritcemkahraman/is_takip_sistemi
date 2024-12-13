import 'package:flutter/material.dart';
import '../../models/workflow_model.dart';
import '../../services/workflow_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import 'create_workflow_screen.dart';
import 'workflow_detail_screen.dart';

class WorkflowListScreen extends StatefulWidget {
  const WorkflowListScreen({Key? key}) : super(key: key);

  @override
  State<WorkflowListScreen> createState() => _WorkflowListScreenState();
}

class _WorkflowListScreenState extends State<WorkflowListScreen> {
  final _workflowService = WorkflowService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'İş Akışları',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateWorkflowScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<WorkflowModel>>(
        stream: _workflowService.getUserWorkflows('current_user_id'), // TODO: Gerçek kullanıcı ID'si eklenecek
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Hata: ${snapshot.error}'),
            );
          }

          final workflows = snapshot.data ?? [];
          if (workflows.isEmpty) {
            return const Center(
              child: Text('Henüz iş akışı bulunmuyor'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: workflows.length,
            itemBuilder: (context, index) {
              final workflow = workflows[index];
              return _buildWorkflowCard(workflow);
            },
          );
        },
      ),
    );
  }

  Widget _buildWorkflowCard(WorkflowModel workflow) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkflowDetailScreen(
                workflowId: workflow.id,
              ),
            ),
          );
        },
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
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _buildStatusChip(workflow.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                workflow.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Oluşturulma: ${_formatDate(workflow.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.update, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Güncelleme: ${_formatDate(workflow.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildProgressIndicator(workflow),
              if (workflow.conditions.isNotEmpty ||
                  workflow.parallelFlows.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildWorkflowFeatures(workflow),
              ],
            ],
          ),
        ),
      ),
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

  Widget _buildProgressIndicator(WorkflowModel workflow) {
    final completedSteps = workflow.steps
        .where((step) => step.status == WorkflowStep.statusCompleted)
        .length;
    final totalSteps = workflow.steps.length;
    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İlerleme: $completedSteps/$totalSteps',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress == 1.0 ? Colors.green : Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowFeatures(WorkflowModel workflow) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (workflow.conditions.isNotEmpty)
          Chip(
            avatar: const Icon(Icons.rule, size: 16),
            label: Text('${workflow.conditions.length} Koşul'),
          ),
        if (workflow.parallelFlows.isNotEmpty)
          Chip(
            avatar: const Icon(Icons.call_split, size: 16),
            label: Text('${workflow.parallelFlows.length} Paralel Akış'),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 