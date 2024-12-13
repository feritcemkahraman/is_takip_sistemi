import 'package:flutter/material.dart';
import 'emoji_picker_widget.dart';
import 'voice_message_recorder.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSendPressed;
  final VoidCallback onAttachmentPressed;
  final Function(String)? onVoiceMessageComplete;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSendPressed,
    required this.onAttachmentPressed,
    this.onVoiceMessageComplete,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _showEmojiPicker = false;
  bool _showVoiceRecorder = false;

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      _showVoiceRecorder = false;
    });
  }

  void _toggleVoiceRecorder() {
    setState(() {
      _showVoiceRecorder = !_showVoiceRecorder;
      _showEmojiPicker = false;
    });
  }

  void _onEmojiSelected(String emoji) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: selection.baseOffset + emoji.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_showEmojiPicker)
          EmojiPickerWidget(onEmojiSelected: _onEmojiSelected),
        if (_showVoiceRecorder && widget.onVoiceMessageComplete != null)
          VoiceMessageRecorder(
            onRecordingComplete: widget.onVoiceMessageComplete!,
          ),
        Container(
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
                  onPressed: widget.onAttachmentPressed,
                ),
                IconButton(
                  icon: Icon(
                    _showEmojiPicker
                        ? Icons.keyboard
                        : Icons.emoji_emotions_outlined,
                  ),
                  onPressed: _toggleEmojiPicker,
                ),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
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
                        widget.onSendPressed(text);
                      }
                    },
                  ),
                ),
                if (widget.onVoiceMessageComplete != null)
                  IconButton(
                    icon: Icon(
                      _showVoiceRecorder ? Icons.close : Icons.mic,
                    ),
                    onPressed: _toggleVoiceRecorder,
                  ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller,
                  builder: (context, value, child) {
                    return IconButton(
                      icon: const Icon(Icons.send),
                      color: value.text.trim().isEmpty
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                      onPressed: value.text.trim().isEmpty
                          ? null
                          : () => widget.onSendPressed(value.text),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 