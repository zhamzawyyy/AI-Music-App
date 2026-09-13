import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/services/api_client.dart';

/// Records a short clip and sends it to the backend's /recognition/identify
/// endpoint. Nothing is stored beyond the temporary local file needed to
/// upload it, and the clip is deleted right after the request completes.
class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  final _recorder = AudioRecorder();
  bool _recording = false;
  bool _identifying = false;
  String? _resultText;
  String? _error;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() {
      _error = null;
      _resultText = null;
    });

    if (!await _recorder.hasPermission()) {
      setState(() => _error = 'Microphone permission is required to identify a song.');
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/clip_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    setState(() => _recording = true);

    // Auto-stop after a short clip -- long enough to identify, short enough
    // to keep the request small and quick.
    Future.delayed(const Duration(seconds: 8), () {
      if (_recording) _stopAndIdentify();
    });
  }

  Future<void> _stopAndIdentify() async {
    final path = await _recorder.stop();
    setState(() {
      _recording = false;
      _identifying = true;
    });

    if (path == null) {
      setState(() {
        _identifying = false;
        _error = 'Recording failed.';
      });
      return;
    }

    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final result = await context.read<ApiClient>().identifyClip(bytes, 'clip.m4a');
      await file.delete();

      setState(() {
        _resultText = result['matched'] == true
            ? '${result['title']} — ${result['artist']}'
            : 'No match found.';
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not identify the clip.');
    } finally {
      setState(() => _identifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identify a song')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Play some music nearby, then tap to listen for 8 seconds.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: (_recording || _identifying) ? null : _startRecording,
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: _recording
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  child: Icon(
                    _recording ? Icons.stop : Icons.hearing,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_identifying) const CircularProgressIndicator(),
              if (_resultText != null)
                Text(_resultText!, style: Theme.of(context).textTheme.titleMedium),
              if (_error != null)
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
      ),
    );
  }
}
