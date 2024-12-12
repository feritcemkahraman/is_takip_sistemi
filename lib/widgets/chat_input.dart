import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSendPressed;
  final VoidCallback onAttachmentPressed;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSendPressed,
    required this.onAttachmentPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: onAttachmentPressed,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Mesaj yazın...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    onSendPressed(text);
                  }
                },
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                return IconButton(
                  icon: const Icon(Icons.send),
                  color: value.text.trim().isEmpty
                      ? Colors.grey
                      : Theme.of(context).colorScheme.primary,
                  onPressed: value.text.trim().isEmpty
                      ? null
                      : () => onSendPressed(value.text),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 