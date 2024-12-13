import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class VoiceMessageRecorder extends StatefulWidget {
  final Function(String) onRecordingComplete;

  const VoiceMessageRecorder({
    super.key,
    required this.onRecordingComplete,
  });

  @override
  State<VoiceMessageRecorder> createState() => _VoiceMessageRecorderState();
}

class _VoiceMessageRecorderState extends State<VoiceMessageRecorder> {
  final _audioRecorder = Record();
  bool _isRecording = false;
  Timer? _timer;
  int _recordDuration = 0;
  String? _recordingPath;
  bool _isPaused = false;

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final appDir = await getTemporaryDirectory();
        _recordingPath =
            '${appDir.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';

        if (await _audioRecorder.hasPermission()) {
          final isRecording = await _audioRecorder.isRecording();
          if (isRecording) {
            await _audioRecorder.stop();
          }

          await _audioRecorder.start(
            path: _recordingPath,
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            samplingRate: 44100,
          );

          setState(() {
            _isRecording = true;
            _isPaused = false;
            _recordDuration = 0;
          });

          _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
            if (!_isPaused) {
              setState(() => _recordDuration++);
            }
          });

          Future.delayed(const Duration(minutes: 5), () {
            if (_isRecording) {
              _stop();
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mikrofon izni gerekli')),
          );
        }
      }
    } catch (e) {
      print('Ses kaydı başlatma hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ses kaydı başlatılamadı: $e')),
      );
    }
  }

  Future<void> _pause() async {
    if (!_isRecording) return;

    try {
      await _audioRecorder.pause();
      setState(() => _isPaused = true);
    } catch (e) {
      print('Ses kaydı duraklatma hatası: $e');
    }
  }

  Future<void> _resume() async {
    if (!_isRecording) return;

    try {
      await _audioRecorder.resume();
      setState(() => _isPaused = false);
    } catch (e) {
      print('Ses kaydı devam ettirme hatası: $e');
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });

      if (path != null && _recordDuration > 1) {
        widget.onRecordingComplete(path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt çok kısa')),
        );
      }
    } catch (e) {
      print('Ses kaydı durdurma hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ses kaydı durdurulamadı: $e')),
      );
    }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    if (!_isRecording) return;

    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
    } catch (e) {
      print('Ses kaydı iptal hatası: $e');
    }
  }

  String _formatDuration(int duration) {
    final minutes = (duration ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording) ...[
            Icon(
              Icons.mic,
              color: _isPaused ? Colors.grey : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(_recordDuration),
              style: TextStyle(
                color: _isPaused ? Colors.grey : Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            if (_isPaused)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: _resume,
              )
            else
              IconButton(
                icon: const Icon(Icons.pause),
                onPressed: _pause,
              ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stop,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _cancel,
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.mic),
              onPressed: _start,
            ),
        ],
      ),
    );
  }
} 