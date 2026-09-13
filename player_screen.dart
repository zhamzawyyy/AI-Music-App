import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String audioUrl;
  const PlayerScreen({super.key, required this.title, required this.audioUrl});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _player = AudioPlayer();
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _player.setUrl(widget.audioUrl);
      setState(() => _ready = true);
      _player.play();
    } catch (e) {
      setState(() => _error = 'Could not play this track.');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: _error != null
            ? Text(_error!)
            : !_ready
                ? const CircularProgressIndicator()
                : StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing ?? false;
                      return IconButton(
                        iconSize: 64,
                        icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
                        onPressed: () => playing ? _player.pause() : _player.play(),
                      );
                    },
                  ),
      ),
    );
  }
}
