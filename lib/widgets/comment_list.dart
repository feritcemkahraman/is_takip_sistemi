import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class CommentList extends StatelessWidget {
  final String taskId;

  const CommentList({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.tasksCollection)
          .doc(taskId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Bir hata oluştu');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Yorum bulunamadı');
        }

        final taskData = snapshot.data!.data() as Map<String, dynamic>;
        final comments = List<String>.from(taskData['comments'] ?? []);

        if (comments.isEmpty) {
          return const Text('Henüz yorum yapılmamış');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(comments[index]),
              ),
            );
          },
        );
      },
    );
  }
}
