import 'package:flutter/material.dart';
import '../models/workflow_model.dart';
import '../services/workflow/workflow_service.dart';
import '../services/auth_service.dart';
import '../widgets/file_upload_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class WorkflowDetailScreen extends StatefulWidget {
  final WorkflowModel workflow;

  const WorkflowDetailScreen({
    super.key,
    required this.workflow,
  });

  @override
  State<WorkflowDetailScreen> createState() => _WorkflowDetailScreenState();
}

class _WorkflowDetailScreenState extends State<WorkflowDetailScreen> {
  final WorkflowService _workflowService = WorkflowService();
  final AuthService _authService = AuthService();
  final _commentController = TextEditingController();
  String? _userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.workflow.title),
          actions: [
            if (widget.workflow.canEdit(_userId!))
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editWorkflow(),
              ),
            if (widget.workflow.canDelete(_userId!))
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteWorkflow(),
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Detaylar'),
              Tab(text: 'Adımlar'),
              Tab(text: 'Yorumlar'),
              Tab(text: 'Dosyalar'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildDetailsTab(),
                  _buildStepsTab(),
                  _buildCommentsTab(),
                  _buildFilesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildProgressCard(),
          const SizedBox(height: 16),
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genel Bilgiler',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Tür', widget.workflow.type),
            _buildInfoRow('Durum', widget.workflow.status),
            _buildInfoRow('Öncelik', widget.workflow.priorityText),
            if (widget.workflow.deadline != null)
              _buildInfoRow('Son Tarih', widget.workflow.remainingTimeText),
            _buildInfoRow('Oluşturan', widget.workflow.createdBy),
            _buildInfoRow(
              'Oluşturma Tarihi',
              widget.workflow.createdAt.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = widget.workflow.steps.where((step) => step.isCompleted).length /
        widget.workflow.steps.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İlerleme',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text('${(progress * 100).toInt()}% Tamamlandı'),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<List<WorkflowHistory>>(
      stream: _workflowService.getHistory(widget.workflow.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Bir hata oluştu: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = snapshot.data!;
        if (history.isEmpty) {
          return const Center(
            child: Text('Henüz geçmiş kaydı bulunmuyor'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Geçmiş',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(item.action),
                  subtitle: Text(item.timestamp.toString()),
                  trailing: Text(item.userId),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.workflow.steps.length,
      itemBuilder: (context, index) {
        final step = widget.workflow.steps[index];
        final isCurrentStep = widget.workflow.currentStep?.id == step.id;
        final canEdit = isCurrentStep && step.assignedTo == _userId;

        return Card(
          color: isCurrentStep ? Colors.blue.withOpacity(0.1) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStepStatusColor(step.status),
              child: Text('${index + 1}'),
            ),
            title: Text(step.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.description),
                const SizedBox(height: 4),
                Text(
                  'Durum: ${_getStepStatusText(step.status)}',
                  style: TextStyle(
                    color: _getStepStatusColor(step.status),
                  ),
                ),
                Text('Atanan: ${step.assignedTo}'),
              ],
            ),
            trailing: canEdit
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () => _completeStep(step),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _rejectStep(step),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.workflow.comments.length,
            itemBuilder: (context, index) {
              final comment = widget.workflow.comments[index];
              return Card(
                child: ListTile(
                  title: Text(comment.comment),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment.timestamp.toString()),
                      if (comment.attachments.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: comment.attachments
                              .map((url) => Chip(
                                    label: Text(url.split('/').last),
                                    onDeleted: () {},
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                  trailing: Text(comment.userId),
                ),
              );
            },
          ),
        ),
        if (widget.workflow.canAddComment(_userId!))
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Yorum ekle...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilesTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.workflow.files.length,
            itemBuilder: (context, index) {
              final file = widget.workflow.files[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.file_present),
                  title: Text(file.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Boyut: ${_formatFileSize(file.size)}'),
                      Text('Yükleyen: ${file.uploadedBy}'),
                      Text('Tarih: ${file.uploadedAt}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {},
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.workflow.canAddFile(_userId!))
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _handleFileUpload,
              child: const Text('Dosya Yükle'),
            ),
          ),
      ],
    );
  }

  Color _getStepStatusColor(String status) {
    switch (status) {
      case WorkflowStep.statusActive:
        return Colors.blue;
      case WorkflowStep.statusCompleted:
        return Colors.green;
      case WorkflowStep.statusRejected:
        return Colors.red;
      case WorkflowStep.statusSkipped:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStepStatusText(String status) {
    switch (status) {
      case WorkflowStep.statusActive:
        return 'Aktif';
      case WorkflowStep.statusCompleted:
        return 'Tamamlandı';
      case WorkflowStep.statusRejected:
        return 'Reddedildi';
      case WorkflowStep.statusSkipped:
        return 'Atlandı';
      default:
        return 'Bekliyor';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _completeStep(WorkflowStep step) async {
    setState(() => _isLoading = true);
    try {
      await _workflowService.updateStepStatus(
        widget.workflow.id,
        step.id,
        WorkflowStep.statusCompleted,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adım tamamlandı')),
        );
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

  Future<void> _rejectStep(WorkflowStep step) async {
    setState(() => _isLoading = true);
    try {
      await _workflowService.updateStepStatus(
        widget.workflow.id,
        step.id,
        WorkflowStep.statusRejected,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adım reddedildi')),
        );
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

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _workflowService.addComment(
        widget.workflow.id,
        _userId!,
        _commentController.text,
      );
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum eklendi')),
        );
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

  void _handleFileUpload() async {
    if (!widget.workflow.canAddFile(_userId!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu iş akışına dosya ekleme yetkiniz yok.'),
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = result.files.first;
      final fileName = file.name;
      final fileBytes = file.bytes;

      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya okunamadı.'),
          ),
        );
        return;
      }

      // Dosyayı Storage'a yükle
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('workflows/${widget.workflow.id}/$fileName');
      
      try {
        await storageRef.putData(fileBytes);
        final downloadUrl = await storageRef.getDownloadURL();

        // Dosyayı iş akışına ekle
        await _workflowService.addFile(
          widget.workflow.id,
          downloadUrl,
          fileName,
          _userId!,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya başarıyla yüklendi.'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya yüklenirken hata oluştu: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _editWorkflow() async {
    // TODO: İş akışı düzenleme ekranına yönlendir
  }

  Future<void> _deleteWorkflow() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İş Akışını Sil'),
        content: const Text('Bu iş akışını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        await _workflowService.deleteWorkflow(widget.workflow.id);
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
}