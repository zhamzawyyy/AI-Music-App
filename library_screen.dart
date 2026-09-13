import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/services/api_client.dart';
import '../../shared/services/token_storage.dart';
import '../player/player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<dynamic> _tracks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tracks = await context.read<ApiClient>().listTracks();
      setState(() => _tracks = tracks);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not load your library.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await context.read<ApiClient>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My library'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Log out'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _tracks.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('No tracks yet. Generate your first one!')),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _tracks.length,
                        itemBuilder: (context, index) {
                          final track = _tracks[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.music_note)),
                            title: Text(track['title'] ?? 'Untitled'),
                            subtitle: Text(track['is_ai_generated'] == true ? 'AI generated' : 'Uploaded'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await context.read<ApiClient>().deleteTrack(track['id']);
                                _load();
                              },
                            ),
                            onTap: () {
                              if (track['audio_url'] != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PlayerScreen(
                                      title: track['title'] ?? 'Untitled',
                                      audioUrl: track['audio_url'],
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.library_music), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Generate'),
          NavigationDestination(icon: Icon(Icons.hearing), label: 'Identify'),
        ],
        onDestinationSelected: (index) {
          if (index == 1) context.push('/generate');
          if (index == 2) context.push('/identify');
        },
      ),
    );
  }
}
