import 'package:flutter/material.dart';
import '../models/workflow_model.dart';
import '../services/workflow_service.dart';
import '../services/auth_service.dart';
import 'workflow_detail_screen.dart';
import 'create_workflow_screen.dart';

class WorkflowListScreen extends StatefulWidget {
  const WorkflowListScreen({super.key});

  @override
  State<WorkflowListScreen> createState() => _WorkflowListScreenState();
}

class _WorkflowListScreenState extends State<WorkflowListScreen>
    with SingleTickerProviderStateMixin {
  final WorkflowService _workflowService = WorkflowService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('İş Akışları'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aktif İş Akışları'),
            Tab(text: 'Şablonlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkflowList(),
          _buildTemplateList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateWorkflowScreen(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWorkflowList() {
    return StreamBuilder<List<WorkflowModel>>(
      stream: _workflowService.getUserWorkflows(_userId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Bir hata oluştu: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final workflows = snapshot.data!;
        if (workflows.isEmpty) {
          return const Center(
            child: Text('Aktif iş akışı bulunmuyor'),
          );
        }

        return ListView.builder(
          itemCount: workflows.length,
          itemBuilder: (context, index) {
            final workflow = workflows[index];
            return _buildWorkflowItem(workflow);
          },
        );
      },
    );
  }

  Widget _buildTemplateList() {
    return StreamBuilder<List<WorkflowModel>>(
      stream: _workflowService.getTemplates(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Bir hata oluştu: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final templates = snapshot.data!;
        if (templates.isEmpty) {
          return const Center(
            child: Text('Şablon bulunmuyor'),
          );
        }

        return ListView.builder(
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return _buildTemplateItem(template);
          },
        );
      },
    );
  }

  Widget _buildWorkflowItem(WorkflowModel workflow) {
    final currentStep = workflow.currentStep;
    final progress = workflow.steps.where((step) => step.isCompleted).length /
        workflow.steps.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(workflow.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(workflow.description),
            const SizedBox(height: 8),
            if (currentStep != null) Text('Mevcut Adım: ${currentStep.title}'),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 4),
            Text('İlerleme: %${(progress * 100).toInt()}'),
          ],
        ),
        trailing: _buildWorkflowStatus(workflow.status),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkflowDetailScreen(workflow: workflow),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateItem(WorkflowModel template) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(template.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.description),
            const SizedBox(height: 8),
            Text('Adım Sayısı: ${template.steps.length}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () => _startWorkflow(template),
        ),
      ),
    );
  }

  Widget _buildWorkflowStatus(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case WorkflowModel.statusActive:
        icon = Icons.play_arrow;
        color = Colors.blue;
        break;
      case WorkflowModel.statusCompleted:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case WorkflowModel.statusCancelled:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.hourglass_empty;
        color = Colors.grey;
    }

    return Icon(icon, color: color);
  }

  Future<void> _startWorkflow(WorkflowModel template) async {
    try {
      final workflow = await _workflowService.createFromTemplate(
        template.id,
        _userId!,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkflowDetailScreen(workflow: workflow),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İş akışı başlatılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 