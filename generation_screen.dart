import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/services/api_client.dart';

class GenerationScreen extends StatefulWidget {
  const GenerationScreen({super.key});

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen> {
  final _promptController = TextEditingController();
  bool _submitting = false;
  String? _status; // pending / running / completed / failed
  String? _error;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() => _error = 'Describe the music you want first.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _status = null;
    });

    final api = context.read<ApiClient>();
    try {
      final job = await api.startGeneration(prompt);
      setState(() => _status = job['status']);
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        final updated = await api.getGenerationStatus(job['id']);
        setState(() => _status = updated['status']);
        if (updated['status'] == 'completed' || updated['status'] == 'failed') {
          timer.cancel();
          setState(() => _submitting = false);
          if (updated['status'] == 'failed') {
            setState(() => _error = updated['error_message'] ?? 'Generation failed.');
          } else if (mounted) {
            context.go('/library');
          }
        }
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not reach the server.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate music')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Describe the track you want -- genre, mood, tempo, instruments.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              maxLines: 4,
              enabled: !_submitting,
              decoration: const InputDecoration(
                hintText: 'e.g. upbeat lofi hip-hop with soft piano and vinyl crackle',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _generate,
              child: _submitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text(_status == null ? 'Starting...' : 'Generating ($_status)...'),
                      ],
                    )
                  : const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }
}
